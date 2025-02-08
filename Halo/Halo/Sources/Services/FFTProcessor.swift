import Accelerate

final class FFTProcessor {
    private let setup: vDSP_DFT_Setup
    private let windowSize: Int
    
    init(windowSize: Int) {
        self.windowSize = windowSize
        self.setup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(windowSize),
            vDSP_DFT_Direction.FORWARD
        )!
    }
    
    deinit {
        vDSP_DFT_DestroySetup(setup)
    }
    
    func process(_ input: [Float]) -> (realPart: [Float], imagPart: [Float]) {
        var realPart = [Float](repeating: 0, count: windowSize)
        var imagPart = [Float](repeating: 0, count: windowSize)
        
        // Apply window
        var window = [Float](repeating: 0, count: windowSize)
        vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_DENORM))
        vDSP_vmul(input, 1, window, 1, &realPart, 1, vDSP_Length(windowSize))
        
        // Perform FFT
        vDSP_DFT_Execute(
            setup,
            realPart.withUnsafeMutableBufferPointer { $0.baseAddress! },
            imagPart.withUnsafeMutableBufferPointer { $0.baseAddress! },
            realPart.withUnsafeMutableBufferPointer { $0.baseAddress! },
            imagPart.withUnsafeMutableBufferPointer { $0.baseAddress! }
        )
        
        return (realPart, imagPart)
    }
}
