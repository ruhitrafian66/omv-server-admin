import Foundation
import Security

class ConnectionManager: ObservableObject {
    @Published var isConnected = false
    @Published var serverIP = ""
    @Published var serverPort = "80"
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    private var sessionToken: String?
    private var username: String?
    
    func attemptAutoConnect() {
        guard let credentials = loadCredentials() else {
            return
        }
        
        serverIP = credentials.ip
        serverPort = credentials.port
        username = credentials.username
        
        Task {
            await connect(ip: credentials.ip, port: credentials.port, 
                         username: credentials.username, password: credentials.password)
        }
    }
    
    @MainActor
    func connect(ip: String, port: String, username: String, password: String) async {
        isConnecting = true
        errorMessage = nil
        
        do {
            let token = try await OMVAPIClient.shared.login(
                ip: ip, port: port, username: username, password: password
            )
            
            self.sessionToken = token
            self.serverIP = ip
            self.serverPort = port
            self.username = username
            self.isConnected = true
            
            saveCredentials(ip: ip, port: port, username: username, password: password)
        } catch {
            self.errorMessage = error.localizedDescription
            self.isConnected = false
        }
        
        isConnecting = false
    }
    
    func disconnect() {
        isConnected = false
        sessionToken = nil
    }
    
    func getSessionToken() -> String? {
        return sessionToken
    }
    
    private func saveCredentials(ip: String, port: String, username: String, password: String) {
        UserDefaults.standard.set(ip, forKey: "serverIP")
        UserDefaults.standard.set(port, forKey: "serverPort")
        UserDefaults.standard.set(username, forKey: "username")
        
        let passwordData = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "omv_password",
            kSecValueData as String: passwordData
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadCredentials() -> (ip: String, port: String, username: String, password: String)? {
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
}
