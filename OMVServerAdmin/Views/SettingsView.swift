import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var isMonitoringEnabled = BackgroundMonitoringService.shared.isMonitoringEnabled
    @State private var showingPermissionAlert = false
    @State private var permissionGranted = false
    
    var body: some View {
        Form {
            Section(header: Text("Background Monitoring")) {
                Toggle("Server Availability Alerts", isOn: $isMonitoringEnabled)
                    .onChange(of: isMonitoringEnabled) { newValue in
                        if newValue {
                            requestPermissionsAndEnable()
                        } else {
                            BackgroundMonitoringService.shared.isMonitoringEnabled = false
                        }
                    }
                
                if isMonitoringEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Monitoring Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                        
                        Text("The app will check if your server is available when connected to \"DeadLock\" WiFi network.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Checks occur approximately every 15-30 minutes in the background.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Button("Test Notification") {
                        testNotification()
                    }
                    .font(.subheadline)
                }
            }
            
            Section(header: Text("Connection")) {
                HStack {
                    Text("Server")
                    Spacer()
                    Text("\(connectionManager.serverIP):\(connectionManager.serverPort)")
                        .foregroundColor(.secondary)
                }
                
                Button("Disconnect") {
                    connectionManager.disconnect()
                }
                .foregroundColor(.red)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("OK") {
                isMonitoringEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive server availability alerts.")
        }
    }
    
    private func requestPermissionsAndEnable() {
        Task {
            let granted = await BackgroundMonitoringService.shared.requestNotificationPermissions()
            
            await MainActor.run {
                if granted {
                    BackgroundMonitoringService.shared.isMonitoringEnabled = true
                    permissionGranted = true
                } else {
                    isMonitoringEnabled = false
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func testNotification() {
        Task {
            await BackgroundMonitoringService.shared.sendTestNotification()
        }
    }
}
