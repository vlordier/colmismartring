import SwiftUI

/// Controls for managing different types of data streams from the ring
struct StreamingControls: View {
    @ObservedObject var viewModel: RingViewModel
    let type: StreamingType

    var body: some View {
        Section {
            NavigationLink {
                DashboardView(viewModel: viewModel)
            } label: {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                    Text("View Live Dashboard")
                }
            }
            .buttonStyle(.borderedProminent)
            
            if type == .raw {
                RawStreamControls(viewModel: viewModel)
            } else {
                StandardStreamControls(viewModel: viewModel, type: type)
            }
        } header: {
            Text(type.rawValue)
                .font(.system(size: ViewConstants.FontSize.title, weight: .bold))
        }
    }
}

/// Types of data streams available from the ring device
enum StreamingType: String {
    /// Heart rate monitoring stream
    case heartRate = "Heart Rate"
    /// Blood oxygen level stream
    case spo2 = "SPO2"
    /// X-axis acceleration stream
    case accelerometerX = "Accelerometer X"
    /// Y-axis acceleration stream
    case accelerometerY = "Accelerometer Y"
    /// Z-axis acceleration stream
    case accelerometerZ = "Accelerometer Z"
    /// Raw sensor data stream
    case raw = "Raw Data"

    var iconName: String {
        switch self {
        case .heartRate:
            "heart.fill"
        case .spo2:
            "lungs.fill"
        case .accelerometerX:
            "arrow.left.and.right"
        case .accelerometerY:
            "arrow.up.and.down"
        case .accelerometerZ:
            "arrow.clockwise"
        case .raw:
            "waveform.path"
        }
    }
    
    var realTimeReading: RealTimeReading {
        switch self {
        case .heartRate:
            return .heartRate
        case .spo2:
            return .spo2
        case .accelerometerX:
            return .accelerometerX
        case .accelerometerY:
            return .accelerometerY
        case .accelerometerZ:
            return .accelerometerZ
        case .raw:
            return .heartRate // Default to heartRate for raw type, since raw uses a different streaming mechanism
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
private struct StandardStreamControls: View {
    @ObservedObject var viewModel: RingViewModel
    let type: StreamingType
    
    var body: some View {
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
    }
}

private struct RawStreamControls: View {
    @ObservedObject var viewModel: RingViewModel
    @State private var selectedStreamType: RawStreamType = .blood
    
    var body: some View {
        VStack(spacing: ViewConstants.Spacing.medium) {
            Picker("Stream Type", selection: $selectedStreamType) {
                Text("Blood").tag(RawStreamType.blood)
                Text("HRS").tag(RawStreamType.hrs)
                Text("Accelerometer").tag(RawStreamType.accelerometer)
            }
            .pickerStyle(.segmented)
            .padding(.bottom)
            
            if viewModel.isRawStreaming {
                Text("Active Stream: \(selectedStreamType.rawValue)")
                    .foregroundColor(.green)
            }
            
            Button(action: {
                viewModel.ringSessionManager.startRawStream(type: selectedStreamType)
            }) {
                ActionButton(title: "Start Raw Stream", color: ViewConstants.Colors.success)
            }
            
            Button(action: {
                viewModel.ringSessionManager.stopRawStream()
            }) {
                ActionButton(title: "Stop Raw Stream", color: ViewConstants.Colors.error)
            }
        }
    }
}
