//
//  HeartRateGraphView.swift
//  Halo
//
//  Created by Yannis De Cleene on 27/01/2025.
//

import Charts
import SwiftUI

struct HeartRateDataPoint: Identifiable {
    let id = UUID() // Unique identifier for each data point
    let heartRate: Int // Heart rate value
    let time: Date // Timestamp of the heart rate measurement
}

struct HeartRateGraphView: View {
    let heartRateDataPoints: [HeartRateDataPoint] // Array of heart rate data points

    // Formatter for displaying time in a short style
    private static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) { // Layout stack with consistent spacing
            // Check if there is any heart rate data to display
            if heartRateDataPoints.isEmpty {
                EmptyStateView()
            } else {
                Text("Heart Rate Over Time")
                    .font(.system(size: 20, weight: .bold)) // Set title font size and weight
                    .padding(.horizontal)

                Chart {
                    // Plot each valid heart rate data point on the graph
                    ForEach(filterValidHeartRateDataPoints(heartRateDataPoints)) { dataPoint in
                        LineMark(
                            x: .value("Time", dataPoint.time),
                            y: .value("Heart Rate", dataPoint.heartRate)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.red) // Set line color for heart rate data
                    }
                }
                .chartYAxis {
                    // Configure y-axis with automatic tick marks for heart rate
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { axisValue in
                        if let heartRateValue = axisValue.as(Int.self) {
                            // Display heart rate value with units on y-axis
                            AxisValueLabel { // Implicit return
                                Text("\(heartRateValue) bpm") // Display heart rate with units
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    // Configure x-axis with automatic tick marks for time
                    AxisMarks(values: .automatic) { axisValue in
                        if let dateValue = axisValue.as(Date.self) {
                            AxisValueLabel { // Implicit return
                                Text(Self.timeFormatter.string(from: dateValue)) // Format and display date labels
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .frame(height: 300)
                .accessibilityLabel("Heart rate graph showing measurements over time")
            }
        }
    }

    // Validate data points to ensure heart rate values are within a realistic range
    private func filterValidHeartRateDataPoints(_ dataPoints: [HeartRateDataPoint]) -> [HeartRateDataPoint] {
        return dataPoints.filter { $0.heartRate > 30 && $0.heartRate < 220 }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) { // Replaced ViewConstants.Spacing.medium with 16
            Image(systemName: "heart.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Heart Rate Data Available")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Take a measurement to see your heart rate data here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .padding()
    }
}

struct HeartRateGraphView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with data
            HeartRateGraphView(data: [
                HeartRateDataPoint(heartRate: 72, time: Date()),
                HeartRateDataPoint(heartRate: 75, time: Date().addingTimeInterval(3600)),
                HeartRateDataPoint(heartRate: 70, time: Date().addingTimeInterval(7200)),
            ])

            // Preview empty state
            HeartRateGraphView(data: [])
        }
        .previewLayout(.sizeThatFits)
    }
}
