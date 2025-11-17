import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var cpuStats: CPUStats?
    @Published var memoryStats: MemoryStats?
    @Published var fileSystems: [FileSystemStats] = []
    @Published var updateInfo: UpdateInfo?
    @Published var isLoading = false
    @Published var isUpdating = false
    @Published var isPowerActionInProgress = false
    @Published var updateStatus: UpdateStatus?
    
    enum UpdateStatus {
        case success
        case error(String)
    }
    
    private var timer: Timer?
    private var cpuHistory: [CPUHistoryPoint] = []
    
    func startMonitoring() {
        print("🚀 Starting dashboard monitoring...")
        refresh()
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateStats()
            }
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func refresh() {
        Task {
            isLoading = true
            await updateStats()
            await loadFileSystems()
            await checkUpdates()
            isLoading = false
        }
    }
    
    private func updateStats() async {
        print("🔄 Starting stats update...")
        do {
            print("📊 Fetching CPU stats...")
            let cpu = try await OMVAPIClient.shared.getCPUStats()
            print("✅ CPU stats received: \(cpu.currentUsage)%")
            
            let historyPoint = CPUHistoryPoint(timestamp: Date(), usage: cpu.currentUsage)
            cpuHistory.append(historyPoint)
            
            if cpuHistory.count > 60 {
                cpuHistory.removeFirst()
            }
            
            self.cpuStats = CPUStats(currentUsage: cpu.currentUsage, history: cpuHistory)
            
            print("💾 Fetching memory stats...")
            let memory = try await OMVAPIClient.shared.getMemoryStats()
            print("✅ Memory stats received: \(memory.usedGB)GB / \(memory.totalGB)GB")
            self.memoryStats = memory
        } catch {
            print("❌ Error updating stats: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    private func loadFileSystems() async {
        print("💿 Fetching file systems...")
        do {
            let systems = try await OMVAPIClient.shared.getFileSystemStats()
            print("✅ File systems received: \(systems.count) systems")
            self.fileSystems = systems
        } catch {
            print("❌ Error loading file systems: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    private func checkUpdates() async {
        print("🔄 Checking for updates...")
        do {
            let info = try await OMVAPIClient.shared.checkUpdates()
            print("✅ Update info received: \(info.count) updates available")
            self.updateInfo = info
        } catch {
            print("❌ Error checking updates: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    func performUpdate() {
        Task {
            isUpdating = true
            updateStatus = nil
            
            do {
                print("🔄 Starting system update...")
                try await OMVAPIClient.shared.performUpdate()
                print("✅ Update completed successfully")
                updateStatus = .success
                
                // Wait a moment then check for new updates
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await checkUpdates()
                
                // Clear success message after 5 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 more seconds
                updateStatus = nil
            } catch {
                print("❌ Error performing update: \(error)")
                updateStatus = .error(error.localizedDescription)
                
                // Clear error message after 10 seconds
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                updateStatus = nil
            }
            
            isUpdating = false
        }
    }
    
    func shutdownServer() {
        Task {
            isPowerActionInProgress = true
            do {
                try await OMVAPIClient.shared.shutdown()
            } catch {
                print("Error shutting down: \(error)")
            }
            isPowerActionInProgress = false
        }
    }
    
    func rebootServer() {
        Task {
            isPowerActionInProgress = true
            do {
                try await OMVAPIClient.shared.reboot()
            } catch {
                print("Error rebooting: \(error)")
            }
            isPowerActionInProgress = false
        }
    }
}
