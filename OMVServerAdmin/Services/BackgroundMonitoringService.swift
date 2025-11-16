import Foundation
import BackgroundTasks
import UserNotifications
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

class BackgroundMonitoringService {
    static let shared = BackgroundMonitoringService()
    
    private let taskIdentifier = "com.omvadmin.servercheck"
    private let targetSSID = "DeadLock"
    private let monitoringEnabledKey = "backgroundMonitoringEnabled"
    private let driveAlertEnabledKey = "driveAlertEnabled"
    private let driveAlertThreshold = 90
    
    var isMonitoringEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: monitoringEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: monitoringEnabledKey)
            if newValue {
                scheduleBackgroundTask()
            } else {
                cancelBackgroundTask()
            }
        }
    }
    
    var isDriveAlertEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: driveAlertEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: driveAlertEnabledKey)
        }
    }
    
    private init() {}
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task scheduled")
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        scheduleBackgroundTask()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await performServerCheck()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func performServerCheck() async {
        guard isMonitoringEnabled else {
            print("Background monitoring is disabled")
            return
        }
        
        guard await isConnectedToTargetWiFi() else {
            print("Not connected to \(targetSSID)")
            return
        }
        
        print("Connected to \(targetSSID), checking server...")
        
        guard let credentials = loadCredentials() else {
            print("No saved credentials")
            return
        }
        
        let isAvailable = await checkServerAvailability(
            ip: credentials.ip,
            port: credentials.port
        )
        
        if !isAvailable {
            await sendServerUnavailableNotification()
            return
        }
        
        // Check drive usage if enabled
        if isDriveAlertEnabled {
            await checkDriveUsage(ip: credentials.ip, port: credentials.port)
        }
    }
    
    func cancelBackgroundTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        print("Background task cancelled")
    }
    
    private func isConnectedToTargetWiFi() async -> Bool {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return false
        }
        
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                  let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                continue
            }
            
            if ssid == targetSSID {
                return true
            }
        }
        
        return false
    }
    
    private func checkServerAvailability(ip: String, port: String) async -> Bool {
        guard let url = URL(string: "http://\(ip):\(port)/rpc.php") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode < 500
            }
            return false
        } catch {
            print("Server check failed: \(error)")
            return false
        }
    }
    
    private func checkDriveUsage(ip: String, port: String) async {
        do {
            // Login first to get session token
            guard let credentials = loadFullCredentials() else {
                print("No credentials for drive check")
                return
            }
            
            let token = try await loginForBackgroundCheck(ip: ip, port: port, 
                                                          username: credentials.username, 
                                                          password: credentials.password)
            
            let fileSystems = try await getFileSystemsForBackgroundCheck(ip: ip, port: port, token: token)
            
            let fullDrives = fileSystems.filter { $0.percentage >= driveAlertThreshold }
            
            if !fullDrives.isEmpty {
                await sendDriveFullNotification(drives: fullDrives)
            }
        } catch {
            print("Failed to check drive usage: \(error)")
        }
    }
    
    private func loginForBackgroundCheck(ip: String, port: String, username: String, password: String) async throws -> String {
        guard let url = URL(string: "http://\(ip):\(port)/rpc.php") else {
            throw NSError(domain: "BackgroundMonitoring", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let params: [String: Any] = [
            "service": "Session",
            "method": "login",
            "params": [
                "username": username,
                "password": password
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let response = json?["response"] as? [String: Any],
              let token = response["authenticated"] as? String ?? response["sessionid"] as? String else {
            throw NSError(domain: "BackgroundMonitoring", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])
        }
        
        return token
    }
    
    private func getFileSystemsForBackgroundCheck(ip: String, port: String, token: String) async throws -> [FileSystemStats] {
        guard let url = URL(string: "http://\(ip):\(port)/rpc.php") else {
            throw NSError(domain: "BackgroundMonitoring", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let params: [String: Any] = [
            "service": "FileSystemMgmt",
            "method": "enumerateMountedFilesystems",
            "params": [
                "start": 0,
                "limit": -1
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "X-Openmediavault-Sessionid")
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let response = json?["response"] as? [String: Any],
              let dataArray = response["data"] as? [[String: Any]] else {
            return []
        }
        
        return dataArray.compactMap { item in
            guard let devicefile = item["devicefile"] as? String,
                  let available = item["available"] as? String,
                  let used = item["used"] as? String,
                  let percentage = item["percentage"] as? Int else {
                return nil
            }
            
            return FileSystemStats(
                name: devicefile,
                total: available,
                used: used,
                percentage: percentage
            )
        }
    }
    
    private func sendServerUnavailableNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Server Unavailable"
        content.body = "Your OMV server is not responding on the DeadLock network"
        content.sound = .default
        content.categoryIdentifier = "SERVER_ALERT"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Server unavailable notification sent")
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    private func sendDriveFullNotification(drives: [FileSystemStats]) async {
        let driveList = drives.map { "\($0.name) (\($0.percentage)%)" }.joined(separator: ", ")
        
        let content = UNMutableNotificationContent()
        content.title = "Drive Storage Alert"
        content.body = "Drive(s) over 90% full: \(driveList)"
        content.sound = .default
        content.categoryIdentifier = "DRIVE_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "drive-full-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Drive full notification sent for: \(driveList)")
        } catch {
            print("Failed to send drive notification: \(error)")
        }
    }
    
    private func loadCredentials() -> (ip: String, port: String)? {
        guard let ip = UserDefaults.standard.string(forKey: "serverIP"),
              let port = UserDefaults.standard.string(forKey: "serverPort") else {
            return nil
        }
        return (ip, port)
    }
    
    private func loadFullCredentials() -> (ip: String, port: String, username: String, password: String)? {
        guard let ip = UserDefaults.standard.string(forKey: "serverIP"),
              let port = UserDefaults.standard.string(forKey: "serverPort"),
              let username = UserDefaults.standard.string(forKey: "username") else {
            return nil
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "omv_password",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return (ip, port, username, password)
    }
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Background monitoring is working correctly!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Test notification sent")
        } catch {
            print("Failed to send test notification: \(error)")
        }
    }
}
