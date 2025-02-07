//
//  HeartRateGraphView.swift
//  Halo
//
//  Created by Yannis De Cleene on 27/01/2025.
//

import Charts
import SwiftUI

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let heartRate: Int
    let time: Date
}

struct HeartRateGraphView: View {
    let data: [HeartRateDataPoint]
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: ViewConstants.Spacing.medium) {
            if data.isEmpty {
                EmptyStateView()
            } else {
                Text("Heart Rate Over Time")
                    .font(.system(size: ViewConstants.FontSize.title, weight: .bold))
                    .padding(.horizontal)

                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("Heart Rate", point.heartRate)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(ViewConstants.Colors.primary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { value in
                        if let heartRate = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\(heartRate) bpm")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 900)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
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
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: ViewConstants.Spacing.medium) {
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
