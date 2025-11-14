import Foundation

struct CPUStats {
    let currentUsage: Double
    var history: [CPUHistoryPoint]
}

struct CPUHistoryPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let usage: Double
}

struct MemoryStats {
    let total: Int64
    let used: Int64
    
    var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }
    
    var totalGB: Double {
        return Double(total) / 1_073_741_824
    }
    
    var usedGB: Double {
        return Double(used) / 1_073_741_824
    }
}

struct FileSystemStats: Identifiable {
    let id = UUID()
    let name: String
    let total: String
    let used: String
    let percentage: Int
}

struct UpdateInfo {
    let available: Bool
    let count: Int
    let packages: [String]
}
