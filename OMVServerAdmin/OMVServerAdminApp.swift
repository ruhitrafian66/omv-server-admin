import SwiftUI
import BackgroundTasks

@main
struct OMVServerAdminApp: App {
    @StateObject private var connectionManager = ConnectionManager()
    
    init() {
        BackgroundMonitoringService.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectionManager)
        }
    }
}
