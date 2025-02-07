import Foundation

/// Represents all possible errors that can occur in the Halo app
enum HaloError: LocalizedError {
    // Device Errors
    case deviceNotFound
    case deviceDisconnected
    case deviceNotResponding
    case invalidDeviceState
    
    // Data Errors
    case invalidPacketFormat
    case invalidPacketLength
    case invalidChecksum
    case invalidHeartRateData
    case invalidTimestamp
    case invalidDateRange
    
    // Service Errors
    case bluetoothUnavailable
    case bluetoothUnauthorized
    case healthKitUnavailable
    case healthKitUnauthorized
    
    // Parser Errors
    case parserError(String)
    case invalidDataFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Ring device not found"
        case .deviceDisconnected:
            return "Ring device disconnected"
        case .deviceNotResponding:
            return "Ring device not responding"
        case .invalidDeviceState:
            return "Ring device is in an invalid state"
            
        case .invalidPacketFormat:
            return "Invalid packet format"
        case .invalidPacketLength:
            return "Invalid packet length"
        case .invalidChecksum:
            return "Invalid packet checksum"
        case .invalidHeartRateData:
            return "Invalid heart rate data"
        case .invalidTimestamp:
            return "Invalid timestamp"
        case .invalidDateRange:
            return "Invalid date range"
            
        case .bluetoothUnavailable:
            return "Bluetooth is not available"
        case .bluetoothUnauthorized:
            return "Bluetooth access not authorized"
        case .healthKitUnavailable:
            return "HealthKit is not available"
        case .healthKitUnauthorized:
            return "HealthKit access not authorized"
            
        case .parserError(let details):
            return "Parser error: \(details)"
        case .invalidDataFormat(let details):
            return "Invalid data format: \(details)"
        }
    }
}
