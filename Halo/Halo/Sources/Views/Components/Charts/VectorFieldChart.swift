import SwiftUI
import Charts

struct VectorFieldChart: View {
    let points: [SIMD3<Double>]
    
    var body: some View {
        VStack {
            Text("Acceleration Vectors")
                .font(.system(.headline, design: .rounded))
            
            HStack {
                // XY Plot
                Chart {
                    ForEach(points.indices, id: \.self) { i in
                        PointMark(
                            x: .value("X", points[i].x),
                            y: .value("Y", points[i].y)
                        )
                        .symbol(.circle)
                        .symbolSize(20)
                    }
                }
                .chartXAxisLabel("X-axis")
                .chartYAxisLabel("Y-axis")
                .frame(height: 150)
                
                // XZ Plot
                Chart {
                    ForEach(points.indices, id: \.self) { i in
                        PointMark(
                            x: .value("X", points[i].x),
                            y: .value("Z", points[i].z)
                        )
                        .symbol(.circle)
                        .symbolSize(20)
                    }
                }
                .chartXAxisLabel("X-axis")
                .chartYAxisLabel("Z-axis")
                .frame(height: 150)
            }
            
            // YZ Plot
            Chart {
                ForEach(points.indices, id: \.self) { i in
                    PointMark(
                        x: .value("Y", points[i].y),
                        y: .value("Z", points[i].z)
                    )
                    .symbol(.circle)
                    .symbolSize(20)
                }
            }
            .chartXAxisLabel("Y-axis")
            .chartYAxisLabel("Z-axis")
            .frame(height: 150)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}
