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
            // Silently fail - errors are handled by the UI showing stale data
        }
    }
    
    private func loadFileSystems() async {
        do {
            let systems = try await OMVAPIClient.shared.getFileSystemStats()
            self.fileSystems = systems
        } catch {
            // Silently fail - errors are handled by the UI
        }
    }
    
    private func checkUpdates() async {
        do {
            let info = try await OMVAPIClient.shared.checkUpdates()
            self.updateInfo = info
        } catch {
            // Silently fail - errors are handled by the UI
        }
    }
    
    func performUpdate() {
        Task {
            isUpdating = true
            updateStatus = nil
            
            do {
                try await OMVAPIClient.shared.performUpdate()
                updateStatus = .success
                
                // Wait a moment then check for new updates
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await checkUpdates()
                
                // Clear success message after 5 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 more seconds
                updateStatus = nil
            } catch {
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
            try? await OMVAPIClient.shared.shutdown()
            isPowerActionInProgress = false
        }
    }
    
    func rebootServer() {
        Task {
            isPowerActionInProgress = true
            try? await OMVAPIClient.shared.reboot()
            isPowerActionInProgress = false
        }
    }
}
