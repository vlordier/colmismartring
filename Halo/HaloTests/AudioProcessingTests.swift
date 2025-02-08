import XCTest
@testable import Halo

final class AudioProcessingTests: XCTestCase {
    var processor: StandardAudioProcessor!
    
    override func setUp() {
        super.setUp()
        processor = StandardAudioProcessor(config: .standard)
    }
    
    func testProcessEmptyBuffer() {
        let buffer = [Float](repeating: 0, count: 2048)
        let result = processor.processBuffer(buffer)
        
        XCTAssertFalse(result.frequencies.isEmpty)
        XCTAssertFalse(result.cepstrum.isEmpty)
        XCTAssertEqual(result.frequencies.count, 1024)
        XCTAssertEqual(result.cepstrum.count, 1024)
    }
    
    func testProcessSineWave() {
        // Create a 440Hz sine wave
        let sampleRate: Double = 44100
        let frequency: Double = 440
        let buffer = (0..<2048).map { index in
            Float(sin(2 * .pi * frequency * Double(index) / sampleRate))
        }
        
        let result = processor.processBuffer(buffer)
        
        // Find peak frequency
        let peakFrequency = result.frequencies.max { $0.magnitude < $1.magnitude }?.frequency
        
        // Should be close to 440Hz
        XCTAssertNotNil(peakFrequency)
        if let peak = peakFrequency {
            XCTAssertEqual(peak, 440, accuracy: 5.0)
        }
    }
    
    func testProcessImpulse() {
        // Create an impulse (single spike)
        var buffer = [Float](repeating: 0, count: 2048)
        buffer[0] = 1.0
        
        let result = processor.processBuffer(buffer)
        
        // Flat frequency response for impulse
        let magnitudes = result.frequencies.map { $0.magnitude }
        let mean = magnitudes.reduce(0, +) / Float(magnitudes.count)
        
        // All frequencies should be roughly equal
        for magnitude in magnitudes {
            XCTAssertEqual(magnitude, mean, accuracy: 0.1)
        }
    }
}
