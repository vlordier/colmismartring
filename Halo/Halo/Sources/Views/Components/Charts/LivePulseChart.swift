import SwiftUI
import Charts

/// Displays real-time sensor data in a line chart with current value overlay
struct LivePulseChart: View {
    /// Historical data points to display
    let data: [Double]
    /// Current sensor reading
    let currentValue: Double
    /// Color gradient for the chart line
    let gradient: Gradient
    /// Chart title/label
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            // Chart title
            Text(label)
                .font(.system(size: ViewConstants.FontSize.headline, weight: .semibold, design: .rounded))
            
            // Main chart area
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Value", data[index])
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                RuleMark(y: .value("Current", currentValue))
                    .foregroundStyle(.secondary)
            }
            .chartXAxis(.hidden)
            .chartYScale(domain: [data.min() ?? 0 - 5, data.max() ?? 100 + 5])
            .frame(height: 120)
            .overlay(alignment: .trailing) {
                Text("\(Int(currentValue))")
                    .font(.system(.largeTitle, design: .rounded))
                    .padding()
            }
        }
        .padding(ViewConstants.Spacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(ViewConstants.CornerRadius.medium)
        .modifier(CardStyle())
    }
}
