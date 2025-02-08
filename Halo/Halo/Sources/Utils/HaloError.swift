import Foundation

/// Protocol for errors that can be retried
protocol RetryableError: Error {
    /// Action to retry when the error occurred
    var retryAction: (() -> Void)? { get }
    
    /// Description of steps to resolve the error
    var recoverySteps: String? { get }
    
    /// User-facing suggestions for resolving the error
    var recoverySuggestion: String? { get }
}

/// Represents all possible errors that can occur in the Halo app
enum HaloError: LocalizedError, RetryableError {
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
    case checksumMismatch
    
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
            return "Invalid data packet format received"
        case .invalidPacketLength:
            return "Received packet with invalid length"
        case .invalidChecksum:
            return "Packet checksum verification failed"
        case .invalidHeartRateData:
            return "Invalid heart rate data received"
        case .invalidTimestamp:
            return "Invalid timestamp in data"
        case .invalidDateRange:
            return "Invalid date range specified"
        case .bluetoothUnavailable:
            return "Bluetooth is not available on this device"
        case .bluetoothUnauthorized:
            return "Bluetooth access not authorized"
        case .healthKitUnavailable:
            return "HealthKit is not available on this device"
        case .healthKitUnauthorized:
            return "HealthKit access not authorized"
        case .parserError(let details):
            return "Data parsing error: \(details)"
        case .invalidDataFormat(let details):
            return "Invalid data format: \(details)"
        case .checksumMismatch:
            return "Packet checksum verification failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .deviceNotFound:
            return "Try these steps:\n• Make sure the ring is charged\n• Keep the ring within 30cm of your phone\n• Turn Bluetooth off and on again"
            
        case .deviceDisconnected:
            return "Try these steps:\n• Move closer to the ring\n• Check if the ring needs charging\n• Restart the ring by holding the button for 10 seconds"
            
        case .deviceNotResponding:
            return "Try these steps:\n• Reset the ring by holding the button for 10 seconds\n• Check if the ring needs charging\n• Try moving closer to reduce interference"
            
        case .invalidDeviceState:
            return "Try these steps:\n• Restart the ring by holding the button for 10 seconds\n• Remove the ring from Bluetooth settings\n• Add the ring again through the app"
            
        case .bluetoothUnavailable:
            return "Try these steps:\n• Enable Bluetooth in Settings\n• Restart your phone\n• Check if Bluetooth is blocked in Settings > Privacy"
            
        case .bluetoothUnauthorized:
            return "Try these steps:\n• Go to Settings > Privacy > Bluetooth\n• Enable Bluetooth access for this app\n• Restart the app after enabling access"
            
        case .healthKitUnauthorized:
            return "Try these steps:\n• Go to Settings > Health\n• Tap Data Access & Devices\n• Find this app and enable required permissions"
            
        case .invalidPacketFormat, .invalidPacketLength, .invalidChecksum:
            return "Try these steps:\n• Make sure the ring's firmware is up to date\n• Reset the ring by holding the button for 10 seconds\n• Try reconnecting to the ring"
            
        default:
            return "Try these steps:\n• Check the ring's battery level\n• Ensure the ring is within range\n• Restart the app"
        }
    }
}
