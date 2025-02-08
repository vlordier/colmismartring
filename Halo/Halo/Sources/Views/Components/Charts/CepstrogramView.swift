import SwiftUI
import Charts

struct CepstrogramView: View {
    let data: [Float]
    let frequencyBands: [(frequency: Float, magnitude: Float)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Audio Analysis")
                .font(.system(.headline, design: .rounded))
            
            // Frequency spectrum
            VStack(alignment: .leading) {
                Text("Frequency Spectrum")
                    .font(.subheadline)
                
                Chart {
                    ForEach(frequencyBands.prefix(100), id: \.frequency) { band in
                        LineMark(
                            x: .value("Frequency (Hz)", band.frequency),
                            y: .value("Magnitude (dB)", band.magnitude)
                        )
                        .foregroundStyle(
                            Gradient(colors: [.blue, .purple])
                        )
                    }
                }
                .chartYScale(domain: -60...0)
                .chartXScale(domain: 0...5000)
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 1000)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let freq = value.as(Float.self) {
                                Text("\(Int(freq))")
                            }
                        }
                    }
                }
            }
            
            // Cepstrum
            VStack(alignment: .leading) {
                Text("Cepstrum Analysis")
                    .font(.subheadline)
                
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Quefrency", index),
                            y: .value("Amplitude", value)
                        )
                        .foregroundStyle(
                            Gradient(colors: [.green, .blue])
                        )
                    }
                }
                .chartYScale(domain: -20...20)
                .frame(height: 150)
            }
        }
        .padding(ViewConstants.Spacing.medium)
        .background(.ultraThinMaterial)
        .cornerRadius(ViewConstants.CornerRadius.medium)
        .modifier(CardStyle())
    }
}
