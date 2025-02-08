import Accelerate

final class StandardAudioProcessor: AudioProcessingType {
    private let config: AudioProcessingConfig
    private let fftProcessor: FFTProcessor
    
    init(config: AudioProcessingConfig = .standard) {
        self.config = config
        self.fftProcessor = FFTProcessor(windowSize: config.windowSize)
    }
    
    func processBuffer(_ buffer: [Float]) -> AudioProcessingResult {
        // Perform FFT
        var magnitudes = [Float](repeating: 0, count: config.windowSize / 2)
        let fftResult = fftProcessor.process(buffer)
        fftResult.realPart.withUnsafeBufferPointer { realBuffer in
            fftResult.imagPart.withUnsafeBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: realBuffer.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: imagBuffer.baseAddress!)
                )
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(config.windowSize / 2))
            }
        }
        
        // Convert to dB
        var logMagnitudes = magnitudes
        vDSP_vdbcon(&magnitudes, 1, [20.0], &logMagnitudes, 1, vDSP_Length(config.windowSize / 2), 1)
        
        let frequencies = calculateFrequencies(magnitudes: logMagnitudes)
        
        // Calculate cepstrum
        let cepstrum = calculateCepstrum(magnitudes: logMagnitudes)

        return AudioProcessingResult(
            frequencies: frequencies,
            cepstrum: cepstrum
        )
    }
    
    private func calculateFrequencies(magnitudes: [Float]) -> [(Float, Float)] {
        let binWidth = Float(config.sampleRate) / Float(config.windowSize * 2)
        return magnitudes.enumerated().map { index, magnitude in
            let frequency = Float(index) * binWidth
            return (frequency, magnitude)
        }
    }
    
    private func calculateCepstrum(magnitudes: [Float]) -> [Float] {
        // Convert to log scale
        var tempMagnitudes = magnitudes
        var logMagnitudes = [Float](repeating: 0, count: config.windowSize / 2)
        vDSP_vdbcon(&tempMagnitudes, 1, [20.0], &logMagnitudes, 1, vDSP_Length(config.windowSize / 2), 1)
        
        // Prepare for inverse FFT
        var cepstrum = [Float](repeating: 0, count: config.windowSize / 2)
        var imagPart = [Float](repeating: 0, count: config.windowSize / 2)
        
        // Create inverse FFT setup
        let inverseFftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(config.windowSize / 2),
            vDSP_DFT_Direction.INVERSE
        )!
        defer { vDSP_DFT_DestroySetup(inverseFftSetup) }
        
        // Create a temporary copy for the FFT input
        var tempReal = logMagnitudes
        var tempImag = imagPart
        
        // Perform inverse FFT
        vDSP_DFT_Execute(inverseFftSetup, &tempReal, &tempImag, &cepstrum, &imagPart)
        
        return cepstrum
    }
}
