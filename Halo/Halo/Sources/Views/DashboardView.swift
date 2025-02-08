import SwiftUI

enum TimeRange: String, CaseIterable {
    case realtime = "Live"
    case last5min = "5m"
    case lastHour = "1h"
    case historical = "24h"
}

struct DashboardView: View {
    private func refreshData() async {
        switch selectedTimeRange {
        case .realtime:
            viewModel.refreshCurrentData()
        case .last5min:
            viewModel.refreshLastFiveMinutes()
        case .lastHour:
            viewModel.refreshLastHour() 
        case .historical:
            viewModel.refreshHistoricalData()
        }
    }
    
    @ObservedObject var viewModel: RingViewModel
    @State private var selectedTimeRange: TimeRange = .realtime
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: ViewConstants.Spacing.medium) {
                    HealthMetricsSection(viewModel: viewModel)
                }
                .padding()
            }
            .refreshable {
                await refreshData()
            }
            
            VStack(spacing: 20) {
                TimeRangeSelector(selectedRange: $selectedTimeRange)
                HealthMetricsSection(viewModel: viewModel)
                
                VectorFieldChart(points: viewModel.sensorHistory.accelerometer)
                    .frame(height: 300)
                
                if !viewModel.sensorHistory.rawBlood.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Raw Sensor Streams")
                            .font(.headline)
                        
                        RawDataPlot(
                            values: viewModel.sensorHistory.rawBlood,
                            label: "PPG Raw Signal",
                            color: .green
                        )
                        
                        ForEach(0..<3) { index in
                            RawDataPlot(
                                values: viewModel.sensorHistory.maxValues[index],
                                label: "Max Channel \(index + 1)",
                                color: [.blue, .purple, .pink][index]
                            )
                        }
                    }
                }
            }
            .padding(ViewConstants.Spacing.medium)
        }
        .navigationTitle("Health Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.isLogging.toggle() }) {
                    Image(systemName: viewModel.isLogging ? "recordingtape" : "dot.radiowaves.left.and.right")
                }
            }
        }
    }
}
