import SwiftUI

struct StreamingControls: View {
    @ObservedObject var viewModel: RingViewModel
    let type: StreamingType

    var body: some View {
        Section {
            VStack(spacing: ViewConstants.Spacing.medium) {
                Button(action: {
                    viewModel.ringSessionManager.startRealTimeStreaming(type: type.realTimeReading)
                }) {
                    ActionButton(title: "Start \(type.rawValue) Streaming", color: ViewConstants.Colors.success)
                }

                Button(action: {
                    viewModel.ringSessionManager.continueRealTimeStreaming(type: type.realTimeReading)
                }) {
                    ActionButton(title: "Continue \(type.rawValue) Streaming", color: ViewConstants.Colors.warning)
                }

                Button(action: {
                    viewModel.ringSessionManager.stopRealTimeStreaming(type: type.realTimeReading)
                }) {
                    ActionButton(title: "Stop \(type.rawValue) Streaming", color: ViewConstants.Colors.error)
                }
            }
        } header: {
            Text(type.rawValue)
                .font(.system(size: ViewConstants.FontSize.title, weight: .bold))
        }
    }
}

enum StreamingType: String {
    case heartRate = "Heart Rate"
    case spo2 = "SPO2"

    var iconName: String {
        switch self {
        case .heartRate:
            "heart.fill"
        case .spo2:
            "lungs.fill"
        }
    }
    
    var realTimeReading: RealTimeReading {
        switch self {
        case .heartRate:
            return .heartRate
        case .spo2:
            return .spo2
        }
    }
}

struct StreamingControls_Previews: PreviewProvider {
    static var previews: some View {
        List {
            StreamingControls(
                viewModel: RingViewModel(),
                type: .heartRate
            )
            StreamingControls(
                viewModel: RingViewModel(),
                type: .spo2
            )
        }
        .listStyle(.insetGrouped)
    }
}
