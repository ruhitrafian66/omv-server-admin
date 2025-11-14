import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    serverInfoCard
                    cpuCard
                    memoryCard
                    fileSystemCard
                    updatesCard
                    powerControlCard
                }
                .padding()
            }
            .navigationTitle("Server Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.startMonitoring()
            }
            .onDisappear {
                viewModel.stopMonitoring()
            }
        }
    }
    
    private var serverInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Server")
                .font(.headline)
            Text("\(connectionManager.serverIP):\(connectionManager.serverPort)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var cpuCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Usage")
                .font(.headline)
            
            if let cpu = viewModel.cpuStats {
                HStack {
                    Text("\(Int(cpu.currentUsage))%")
                        .font(.system(size: 36, weight: .bold))
                    Spacer()
                    CircularProgressView(progress: cpu.currentUsage / 100)
                        .frame(width: 60, height: 60)
                }
                
                if !cpu.history.isEmpty {
                    CPUHistoryChart(history: cpu.history)
                        .frame(height: 100)
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .font(.headline)
            
            if let memory = viewModel.memoryStats {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(Int(memory.usedPercentage))%")
                            .font(.system(size: 36, weight: .bold))
                        Text("\(String(format: "%.1f", memory.usedGB)) GB / \(String(format: "%.1f", memory.totalGB)) GB")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    CircularProgressView(progress: memory.usedPercentage / 100)
                        .frame(width: 60, height: 60)
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var fileSystemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File Systems")
                .font(.headline)
            
            if viewModel.fileSystems.isEmpty && !viewModel.isLoading {
                Text("No file systems found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.fileSystems) { fs in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(fs.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(fs.percentage)%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: Double(fs.percentage), total: 100)
                        Text("\(fs.used) used of \(fs.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var updatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Updates")
                .font(.headline)
            
            if let updates = viewModel.updateInfo {
                if updates.available {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(updates.count) updates available")
                                .font(.subheadline)
                            if !updates.packages.isEmpty {
                                Text(updates.packages.prefix(3).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        Button("Update") {
                            viewModel.performUpdate()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isUpdating)
                    }
                } else {
                    Text("System is up to date")
                        .foregroundColor(.secondary)
                }
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var powerControlCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Power Control")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button(action: { viewModel.rebootServer() }) {
                    Label("Restart", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isPowerActionInProgress)
                
                Button(action: { viewModel.shutdownServer() }) {
                    Label("Shutdown", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(viewModel.isPowerActionInProgress)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

}
