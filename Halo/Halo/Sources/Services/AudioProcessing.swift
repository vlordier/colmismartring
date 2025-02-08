import Accelerate

protocol AudioProcessingType {
    func processBuffer(_ buffer: [Float]) -> AudioProcessingResult
}

struct AudioProcessingResult {
    let frequencies: [(frequency: Float, magnitude: Float)]
    let cepstrum: [Float]
}

struct AudioProcessingConfig {
    let windowSize: Int
    let hopSize: Int
    let sampleRate: Double
    
    static let standard = AudioProcessingConfig(
        windowSize: 2048,
        hopSize: 512,
        sampleRate: 44100.0
    )
}
