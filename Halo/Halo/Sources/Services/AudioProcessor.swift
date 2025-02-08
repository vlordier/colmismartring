import AVFoundation

final class AudioProcessor: ObservableObject {
    @Published var cepstrumData: [Float] = []
    @Published var frequencyBands: [(frequency: Float, magnitude: Float)] = []
    
    private let audioProcessor: AudioProcessingType
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    init(audioProcessor: AudioProcessingType = StandardAudioProcessor()) {
        self.audioProcessor = audioProcessor
    }
    
    func startRecording() throws {
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine
        self.inputNode = audioEngine.inputNode
        
        let format = inputNode?.inputFormat(forBus: 0)
        
        try configureAudioSession()
        
        inputNode?.installTap(
            onBus: 0,
            bufferSize: UInt32(AudioProcessingConfig.standard.windowSize),
            format: format
        ) { [weak self] buffer, _ in
            self?.processSampleBuffer(buffer)
        }
        
        try audioEngine.start()
    }
    
    func stopRecording() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
    }
    
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement)
        try session.setActive(true)
    }
    
    private func processSampleBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let count = Int(buffer.frameLength)
        let data = Array(UnsafeBufferPointer(start: channelData, count: count))
        
        let result = audioProcessor.processBuffer(data)
        
        DispatchQueue.main.async {
            self.frequencyBands = result.frequencies
            self.cepstrumData = Array(result.cepstrum.prefix(100))
        }
    }
}
