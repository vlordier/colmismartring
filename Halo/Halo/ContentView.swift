import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RingViewModel()
    @StateObject private var audioProcessor = AudioProcessor()
    @State private var isRecording = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            List {
                if viewModel.ringSessionManager.peripheralConnected {
                    DeviceSection(viewModel: viewModel)
                    CommandsSection(viewModel: viewModel)
                    
                    Section("Battery Status") {
                        Button {
                            viewModel.getBatteryStatus()
                        } label: {
                            ActionButton(title: "Get Battery Status", color: .blue)
                        }
                        
                        if let batteryInfo = viewModel.batteryInfo {
                            BatteryStatusView(batteryInfo: batteryInfo)
                        } else {
                            Text("No battery info available.")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section("Heart Rate Log") {
                        Button {
                            viewModel.getHeartRateLog()
                        } label: {
                            ActionButton(title: "Get Heart Rate Log", color: .green)
                        }
                        
                        HeartRateGraphView(data: viewModel.heartRateData)
                    }
                    
                    StreamingControls(viewModel: viewModel, type: .heartRate)
                    StreamingControls(viewModel: viewModel, type: .spo2)
                    
                    Section("Accelerometer") {
                        StreamingControls(viewModel: viewModel, type: .accelerometerX)
                        StreamingControls(viewModel: viewModel, type: .accelerometerY)
                        StreamingControls(viewModel: viewModel, type: .accelerometerZ)
                        
                        AccelerometerView(ringManager: viewModel.ringSessionManager)
                    }
                    
                    Section("Audio Visualization") {
                        Button {
                            if isRecording {
                                audioProcessor.stopRecording()
                            } else {
                                do {
                                    try audioProcessor.startRecording()
                                } catch {
                                    viewModel.lastError = error
                                    viewModel.showError = true
                                    return  // early exit if starting fails
                                }
                            }
                            isRecording.toggle()
                        } label: {
                            ActionButton(
                                title: isRecording ? "Stop Recording" : "Start Recording",
                                color: isRecording ? .red : .blue
                            )
                        }
                        
                        if !audioProcessor.cepstrumData.isEmpty {
                            CepstrogramView(data: audioProcessor.cepstrumData)
                        }
                    }
                    
                    Section("Data Logging") {
                        // Use shorthand binding if viewModel.isLogging is a Published property.
                        Toggle("Log Sensor Data", isOn: $viewModel.isLogging)
                        
                        if let loggingService = viewModel.loggingService {
                            if !loggingService.getLogFiles().isEmpty {
                                NavigationLink("View Logs") {
                                    LogFilesView(loggingService: loggingService)
                                }
                            } else {
                                Text("No logs available.")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else {
                    Text("No device connected.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Halo Ring")
            .alert("Error", isPresented: $viewModel.showError) {
                if viewModel.canRetry {
                    Button("Retry") {
                        viewModel.retryLastOperation()
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.lastError = nil
                }
            } message: {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.lastError?.localizedDescription ?? "An unknown error occurred")
                        .font(.headline)
                    
                    if let error = viewModel.lastError as? HaloError,
                       let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay {
                if $viewModel.isConnecting {
                    ConnectionOverlay()
                }
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
