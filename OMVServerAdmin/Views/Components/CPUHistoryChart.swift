import SwiftUI

struct CPUHistoryChart: View {
    let history: [CPUHistoryPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !history.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(max(history.count - 1, 1))
                
                for (index, point) in history.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(point.usage) / 100.0 * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}
