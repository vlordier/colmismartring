import Foundation

enum PacketError: LocalizedError {
    case invalidCommand
    case invalidSubDataLength
    case invalidRawCommand
    case checksumMismatch
    
    var errorDescription: String? {
        switch self {
        case .invalidCommand:
            return "Invalid command value"
        case .invalidSubDataLength:
            return "Sub-data length exceeds maximum"
        case .invalidRawCommand:
            return "Invalid raw command format"
        case .checksumMismatch:
            return "Packet checksum verification failed"
        }
    }
}
