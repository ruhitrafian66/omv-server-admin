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
    
    private var timer: Timer?
    private var cpuHistory: [CPUHistoryPoint] = []
    
    func startMonitoring() {
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
        do {
            let cpu = try await OMVAPIClient.shared.getCPUStats()
            
            let historyPoint = CPUHistoryPoint(timestamp: Date(), usage: cpu.currentUsage)
            cpuHistory.append(historyPoint)
            
            if cpuHistory.count > 60 {
                cpuHistory.removeFirst()
            }
            
            self.cpuStats = CPUStats(currentUsage: cpu.currentUsage, history: cpuHistory)
            
            let memory = try await OMVAPIClient.shared.getMemoryStats()
            self.memoryStats = memory
        } catch {
            print("Error updating stats: \(error)")
        }
    }
    
    private func loadFileSystems() async {
        do {
            let systems = try await OMVAPIClient.shared.getFileSystemStats()
            self.fileSystems = systems
        } catch {
            print("Error loading file systems: \(error)")
        }
    }
    
    private func checkUpdates() async {
        do {
            let info = try await OMVAPIClient.shared.checkUpdates()
            self.updateInfo = info
        } catch {
            print("Error checking updates: \(error)")
        }
    }
    
    func performUpdate() {
        Task {
            isUpdating = true
            do {
                try await OMVAPIClient.shared.performUpdate()
                await checkUpdates()
            } catch {
                print("Error performing update: \(error)")
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
