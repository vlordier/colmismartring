import Foundation

/// Protocol defining the interface for parsing heart rate data packets
protocol HeartRateParserType {
    /// Parses a raw data packet into a heart rate log
    /// - Parameter packet: Raw bytes received from the ring device
    /// - Returns: Parsed heart rate log if packet completes a sequence, nil otherwise
    /// - Throws: ModelError if packet format is invalid
    func parse(packet: [UInt8]) throws -> HeartRateLog?
    
    /// Converts raw heart rate values into timestamped measurements
    /// - Parameters:
    ///   - heartRates: Array of heart rate values (typically 288 for 24 hours)
    ///   - timestamp: Base timestamp for the first measurement
    /// - Returns: Array of tuples containing heart rate and corresponding timestamp
    /// - Throws: ModelError if heart rate count is invalid
    func parseHeartRates(_ heartRates: [Int], timestamp: Date) throws -> [(Int, Date)]
}

/// Default implementation of heart rate data parsing
final class HeartRateParser: HeartRateParserType {
    /// Temporary storage for heart rate values being assembled
    private var accumulatedHeartRates: [Int] = []
    
    /// Base timestamp for the current data sequence
    private var measurementStartTime: Date?
    
    /// Total number of packets expected in sequence
    private var expectedPacketCount = 0
    
    /// Current packet index being processed
    private var currentPacketIndex = 0
    
    /// Sampling interval in minutes between measurements
    private var samplingIntervalMinutes = 5
    
    /// Processes an incoming heart rate data packet
    /// - Parameter packet: Raw bytes containing heart rate data
    /// - Returns: Completed heart rate log if sequence is complete, nil otherwise
    /// - Throws: ModelError for invalid packet format
    /// Processes an incoming heart rate data packet and assembles it into the complete log
    /// - Parameter packet: Raw bytes containing heart rate data from the ring device
    /// - Returns: Completed heart rate log if sequence is complete, nil if still receiving packets
    /// - Throws: ModelError if packet format is invalid or data is corrupted
    func parse(packet: [UInt8]) throws -> HeartRateLog? {
        // Validate packet meets minimum required length for heart rate data
        guard packet.count >= 16 else {
            Logger.heartRateError("Received packet with invalid length: \(packet.count)")
            throw ModelError.invalidPacketFormat
        }
        
        let packetType = packet[1] // Second byte indicates packet type
        
        // Handle special reset packet (0xFF) that aborts current sequence
        if packetType == 255 {
            Logger.heartRateInfo("Received reset packet, clearing accumulated data")
            reset()
            return nil
        }
        
        // Handle initialization packet (type 0) that starts a new sequence
        if packetType == 0 {
            // Extract sequence parameters from initialization packet
            expectedPacketCount = Int(packet[2])  // Total packets to expect
            samplingIntervalMinutes = Int(packet[3])  // Minutes between readings
            
            // Pre-allocate array for all heart rate values
            accumulatedHeartRates = Array(repeating: -1, count: expectedPacketCount * 13)
            
            Logger.heartRateInfo("Starting new sequence: expecting \(expectedPacketCount) packets")
            return nil
        }
        
        // Handle timestamp packet
        if packetType == 1 {
            let extractedTimestamp = extractTimestamp(from: packet)
            measurementStartTime = timestampToDate(timestamp: extractedTimestamp)
            
            // Extract first batch of heart rates (9 values)
            let initialDataRange = 0..<9
            let packetDataRange = 6..<15
            accumulatedHeartRates.replaceSubrange(
                initialDataRange,
                with: packet[packetDataRange].map { Int($0) }
            )
            currentPacketIndex += 9
            return nil
        }
        
        // Handle data continuation packet
        let dataStartIndex = currentPacketIndex
        let dataEndIndex = currentPacketIndex + 13
        let packetDataRange = 2..<15
        
        // Store heart rates from current packet
        accumulatedHeartRates.replaceSubrange(
            dataStartIndex..<dataEndIndex,
            with: packetDataRange.map { Int(packet[$0]) }
        )
        currentPacketIndex = dataEndIndex
        
        // Check if this is the final packet
        if packetType == expectedPacketCount - 1,
           let startTime = measurementStartTime {
            // Create complete log with all accumulated data
            let completeLog = HeartRateLog(
                heartRates: Array(accumulatedHeartRates.prefix(288)),
                allPackets: [], // Debug data removed for production
                timestamp: startTime,
                size: expectedPacketCount,
                index: currentPacketIndex,
                range: samplingIntervalMinutes
            )
            reset()
            return completeLog
        }
        
        return nil
    }
    
    func parseHeartRates(_ heartRates: [Int], timestamp: Date) throws -> [(Int, Date)] {
        guard heartRates.count == 288 else {
            throw HaloError.invalidDataFormat("Heart rate count must be 288, got \(heartRates.count)")
        }
        var result: [(Int, Date)] = []
        var current = Calendar.current.startOfDay(for: timestamp)
        let interval = TimeInterval(5 * 60) // 5 minutes
        for hr in heartRates {
            result.append((hr, current))
            current.addTimeInterval(interval)
        }
        return result.filter { $0.0 != 0 }
    }
    
    private func reset() {
        accumulatedHeartRates = []
        measurementStartTime = nil
        expectedPacketCount = 0
        currentPacketIndex = 0
        samplingIntervalMinutes = 5
    }
}
