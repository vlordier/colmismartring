import SwiftUI

struct HealthMetricsSection: View {
    let viewModel: RingViewModel
    
    var body: some View {
        Group {
            LivePulseChart(
                data: viewModel.sensorHistory.heartRate,
                currentValue: Double(viewModel.currentSensorData?.heartRate ?? 0),
                gradient: Gradient(colors: [.red, .orange]),
                label: "Heart Rate"
            )
            
            LivePulseChart(
                data: viewModel.sensorHistory.spo2,
                currentValue: Double(viewModel.currentSensorData?.spo2 ?? 0),
                gradient: Gradient(colors: [.blue, .purple]),
                label: "Blood Oxygen"
            )
        }
    }
}
