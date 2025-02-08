import SwiftUI

/// A view that displays raw sensor data streams for the provided sensor history.
struct RawDataSection: View {
    let sensorHistory: SensorHistory
    
    /// Colors corresponding to the maximum sensor channels.
    private let channelColors: [Color] = [.blue, .purple, .pink]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Raw Sensor Streams")
                .font(.headline)
                .padding(.bottom, 8)
            
            RawDataPlot(
                values: sensorHistory.rawBlood,
                label: "PPG Raw Signal",
                color: .green
            )
            
            // Loop over each max channel in sensorHistory.
            ForEach(sensorHistory.maxValues.indices, id: \.self) { index in
                RawDataPlot(
                    values: sensorHistory.maxValues[index],
                    label: "Max Channel \(index + 1)",
                    // Fallback to gray if there are more channels than colors.
                    color: index < channelColors.count ? channelColors[index] : .gray
                )
            }
        }
        .padding()
    }
}
