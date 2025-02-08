import Foundation

/// Represents errors that can occur during model operations
enum ModelError: LocalizedError {
    /// Heart rate count does not match expected value of 288 (readings every 5 minutes for 24 hours)
    case invalidHeartRateCount(Int)
    
    /// Timestamp data is invalid or missing
    case invalidTimestamp
    
    /// Packet format does not match expected structure
    case invalidPacketFormat
    
    /// Received sensor reading value is not valid
    case invalidSensorReading(UInt8)
    
    /// Human-readable error descriptions
    var errorDescription: String? {
        switch self {
        case .invalidHeartRateCount(let count):
            return "Heart rate count must be 288 (24 hours of 5-minute intervals), got \(count)"
        case .invalidTimestamp:
            return "Invalid timestamp in data packet"
        case .invalidPacketFormat:
            return "Received packet does not match expected format"
        case .invalidSensorReading(let value):
            return "Received invalid sensor reading value: \(value)"
        }
    }
}
