import SwiftUI
import Charts

struct RawDataPlot: View {
    let values: [Double]
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.system(.subheadline, design: .monospaced))
            
            ScrollView(.horizontal) {
                Chart(values.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", values[index])
                    )
                }
                .chartXAxis { AxisMarks(values: .stride(by: 50)) }
                .frame(width: 2000, height: 80)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
