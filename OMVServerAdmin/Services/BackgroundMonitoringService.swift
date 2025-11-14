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
        }
    }
    
    func cancelBackgroundTask() {
        BGTaskScheduler.shared.cancel(taskIdentifier: taskIdentifier)
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
            print("Notification sent")
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    private func loadCredentials() -> (ip: String, port: String)? {
        guard let ip = UserDefaults.standard.string(forKey: "serverIP"),
              let port = UserDefaults.standard.string(forKey: "serverPort") else {
            return nil
        }
        return (ip, port)
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
