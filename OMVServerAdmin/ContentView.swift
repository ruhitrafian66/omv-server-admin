import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showingConnectionSheet = false
    
    var body: some View {
        Group {
            if connectionManager.isConnected {
                DashboardView()
            } else {
                ConnectionView()
            }
        }
        .onAppear {
            connectionManager.attemptAutoConnect()
        }
    }
}
