import Foundation

protocol HeartRatePacketParserType {
    func parsePacket(_ packet: [UInt8]) -> HeartRatePacketResult
}

enum HeartRatePacketResult {
    case initialization(size: Int, interval: Int)
    case timestamp(Date)
    case data([Int])
    case error
    case complete(HeartRateLog)
}

final class HeartRatePacketParser: HeartRatePacketParserType {
    private let timestampParser: TimestampParserType
    
    init(timestampParser: TimestampParserType = TimestampParser()) {
        self.timestampParser = timestampParser
    }
    
    func parsePacket(_ packet: [UInt8]) -> HeartRatePacketResult {
        guard packet.count >= 16 else { return .error }
        
        let subType = packet[1]
        
        if subType == 255 {
            return .error
        }
        
        if subType == 0 {
            let size = Int(packet[2])
            let interval = Int(packet[3])
            return .initialization(size: size, interval: interval)
        }
        
        if subType == 1 {
            if let timestamp = timestampParser.parse(packet[2...5]) {
                let heartRates = Array(packet[6...14]).map { Int($0) }
                return .timestamp(timestamp)
            }
            return .error
        }
        
        // Regular data packet
        let heartRates = Array(packet[2...14]).map { Int($0) }
        return .data(heartRates)
    }
}
