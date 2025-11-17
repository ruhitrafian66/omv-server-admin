import Foundation

enum OMVAPIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case authenticationFailed
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

class OMVAPIClient {
    static let shared = OMVAPIClient()
    
    private var baseURL: String = ""
    private var sessionToken: String?
    
    private init() {}
    
    func login(ip: String, port: String, username: String, password: String) async throws -> String {
        baseURL = "http://\(ip):\(port)"
        
        let params: [String: Any] = [
            "service": "Session",
            "method": "login",
            "params": [
                "username": username,
                "password": password
            ]
        ]
        
        let response: [String: Any] = try await request(endpoint: "/rpc.php", params: params, authenticated: false)
        
        guard let token = response["authenticated"] as? String ?? response["sessionid"] as? String else {
            throw OMVAPIError.authenticationFailed
        }
        
        sessionToken = token
        return token
    }
    
    func getCPUStats() async throws -> CPUStats {
        let params: [String: Any] = [
            "service": "System",
            "method": "getInformation"
        ]
        
        let response: [String: Any] = try await request(endpoint: "/rpc.php", params: params)
        return try parseCPUStats(from: response)
    }
    
    func getMemoryStats() async throws -> MemoryStats {
        let params: [String: Any] = [
            "service": "System",
            "method": "getInformation"
        ]
        
        let response: [String: Any] = try await request(endpoint: "/rpc.php", params: params)
        return try parseMemoryStats(from: response)
    }
    
    func getFileSystemStats() async throws -> [FileSystemStats] {
        let params: [String: Any] = [
            "service": "FileSystemMgmt",
            "method": "enumerateMountedFilesystems",
            "params": [
                "start": 0,
                "limit": -1
            ]
        ]
        
        let response = try await requestRaw(endpoint: "/rpc.php", params: params)
        return try parseFileSystemStats(from: response)
    }
    
    func checkUpdates() async throws -> UpdateInfo {
        let params: [String: Any] = [
            "service": "Apt",
            "method": "getUpgraded"
        ]
        
        let response: [String: Any] = try await request(endpoint: "/rpc.php", params: params)
        return try parseUpdateInfo(from: response)
    }
    
    func performUpdate() async throws {
        let params: [String: Any] = [
            "service": "Apt",
            "method": "upgrade"
        ]
        
        _ = try await request(endpoint: "/rpc.php", params: params)
    }
    
    func shutdown() async throws {
        let params: [String: Any] = [
            "service": "System",
            "method": "shutdown"
        ]
        
        _ = try await request(endpoint: "/rpc.php", params: params)
    }
    
    func reboot() async throws {
        let params: [String: Any] = [
            "service": "System",
            "method": "reboot"
        ]
        
        _ = try await request(endpoint: "/rpc.php", params: params)
    }
    
    private func request(endpoint: String, params: [String: Any], authenticated: Bool = true) async throws -> [String: Any] {
        guard let url = URL(string: baseURL + endpoint) else {
            throw OMVAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = sessionToken {
            request.setValue(token, forHTTPHeaderField: "X-Openmediavault-Sessionid")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        print("📤 API Request: \(params["service"] as? String ?? "").\(params["method"] as? String ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OMVAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw OMVAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OMVAPIError.invalidResponse
        }
        
        // Debug: Print the response
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📥 API Response: \(jsonString)")
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("❌ API Error: \(message)")
            throw OMVAPIError.serverError(message)
        }
        
        return json["response"] as? [String: Any] ?? json
    }
    
    private func requestRaw(endpoint: String, params: [String: Any], authenticated: Bool = true) async throws -> Any {
        guard let url = URL(string: baseURL + endpoint) else {
            throw OMVAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if authenticated, let token = sessionToken {
            request.setValue(token, forHTTPHeaderField: "X-Openmediavault-Sessionid")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        print("📤 API Request: \(params["service"] as? String ?? "").\(params["method"] as? String ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OMVAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw OMVAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OMVAPIError.invalidResponse
        }
        
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("❌ API Error: \(message)")
            throw OMVAPIError.serverError(message)
        }
        
        return json["response"] ?? json
    }
    
    private func parseCPUStats(from response: [String: Any]) throws -> CPUStats {
        let cpuUsage = response["cpuUtilization"] as? Double ?? 0.0
        print("🔍 Parsed CPU: \(cpuUsage)%")
        return CPUStats(currentUsage: cpuUsage, history: [])
    }
    
    private func parseMemoryStats(from response: [String: Any]) throws -> MemoryStats {
        // OMV returns memory values as strings
        let memTotalStr = response["memTotal"] as? String ?? "0"
        let memUsedStr = response["memUsed"] as? String ?? "0"
        
        let memTotal = Int64(memTotalStr) ?? 0
        let memUsed = Int64(memUsedStr) ?? 0
        
        print("🔍 Parsed Memory: \(memUsed) / \(memTotal) bytes")
        return MemoryStats(total: memTotal, used: memUsed)
    }
    
    private func parseFileSystemStats(from response: Any) throws -> [FileSystemStats] {
        // OMV returns file systems as an array
        guard let data = response as? [[String: Any]] else {
            print("🔍 File systems response is not an array, got: \(type(of: response))")
            return []
        }
        
        print("🔍 Parsing \(data.count) file systems")
        
        return data.compactMap { item in
            guard let devicefile = item["devicefile"] as? String,
                  let available = item["available"] as? String,
                  let used = item["used"] as? String,
                  let percentage = item["percentage"] as? Int else {
                print("🔍 Skipping file system - missing fields")
                return nil
            }
            
            print("🔍 Found file system: \(devicefile) at \(percentage)%")
            return FileSystemStats(
                name: devicefile,
                total: available,
                used: used,
                percentage: percentage
            )
        }
    }
    
    private func parseUpdateInfo(from response: [String: Any]) throws -> UpdateInfo {
        guard let data = response["data"] as? [[String: Any]] else {
            return UpdateInfo(available: false, count: 0, packages: [])
        }
        
        let packages = data.compactMap { $0["package"] as? String }
        return UpdateInfo(available: !packages.isEmpty, count: packages.count, packages: packages)
    }
}
