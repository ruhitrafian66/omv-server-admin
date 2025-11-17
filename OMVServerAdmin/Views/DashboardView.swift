import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    cpuMemoryCard
                    fileSystemCard
                    updatesAndPowerCard
                }
                .padding()
            }
            .navigationTitle("Dashboard")
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
    
    private var cpuMemoryCard: some View {
        VStack(spacing: 0) {
            // CPU Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CPU")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let cpu = viewModel.cpuStats {
                        Text("\(Int(cpu.currentUsage))%")
                            .font(.system(size: 28, weight: .semibold))
                    } else {
                        ProgressView()
                    }
                }
                Spacer()
                if let cpu = viewModel.cpuStats {
                    CircularProgressView(progress: cpu.currentUsage / 100)
                        .frame(width: 50, height: 50)
                }
            }
            .padding()
            
            Divider()
            
            // Memory Section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let memory = viewModel.memoryStats {
                        Text("\(Int(memory.usedPercentage))%")
                            .font(.system(size: 28, weight: .semibold))
                        Text("\(String(format: "%.1f", memory.usedGB)) / \(String(format: "%.1f", memory.totalGB)) GB")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        ProgressView()
                    }
                }
                Spacer()
                if let memory = viewModel.memoryStats {
                    CircularProgressView(progress: memory.usedPercentage / 100)
                        .frame(width: 50, height: 50)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var fileSystemCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Storage")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
            
            if viewModel.fileSystems.isEmpty && !viewModel.isLoading {
                Text("No file systems")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.fileSystems) { fs in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fs.name.replacingOccurrences(of: "/dev/", with: ""))
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text("\(fs.used) / \(fs.total)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(fs.percentage)%")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(fs.percentage >= 90 ? .red : fs.percentage >= 75 ? .orange : .primary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        ProgressView(value: Double(fs.percentage), total: 100)
                            .tint(fs.percentage >= 90 ? .red : fs.percentage >= 75 ? .orange : .blue)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        if fs.id != viewModel.fileSystems.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var updatesAndPowerCard: some View {
        VStack(spacing: 0) {
            // Updates Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Updates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if viewModel.isUpdating {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Updating...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            }
                        } else if let status = viewModel.updateStatus {
                            switch status {
                            case .success:
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Updated")
                                        .font(.system(size: 16))
                                        .foregroundColor(.green)
                                }
                            case .error(_):
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text("Failed")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                }
                            }
                        } else if let updates = viewModel.updateInfo {
                            if updates.available {
                                Text("\(updates.count) available")
                                    .font(.system(size: 20, weight: .semibold))
                            } else {
                                Text("Up to date")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ProgressView()
                        }
                    }
                    Spacer()
                    if !viewModel.isUpdating, viewModel.updateStatus == nil, let updates = viewModel.updateInfo, updates.available {
                        Button("Update") {
                            viewModel.performUpdate()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                // Show error details if available
                if case .error(let message) = viewModel.updateStatus {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            .padding()
            
            Divider()
            
            // Power Control Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Power")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Button(action: { viewModel.rebootServer() }) {
                        Label("Restart", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.isPowerActionInProgress)
                    
                    Button(action: { viewModel.shutdownServer() }) {
                        Label("Shutdown", systemImage: "power")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                    .disabled(viewModel.isPowerActionInProgress)
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
