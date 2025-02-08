import Foundation

enum RawStreamType {
    // Represents different types of raw data streams
    case blood // Blood flow data
    case heartRateSensor // Heart rate sensor data
    case accelerometer // Accelerometer data
    
    // String representation of each stream type
    var rawValue: String {
        switch self {
        case .blood:
            return "Blood"
        case .heartRateSensor:
            return "HRS"
        case .accelerometer:
            return "Accelerometer"
        }
    }
}

enum RawSubcommand: UInt8 {
    // Subcommands for starting and stopping raw data streams
    case startBlood = 0x04
    case startHeartRateSensor = 0x01 
    case startAccelerometer = 0x03
    case stop = 0x02
    
    // Maps a RawStreamType to its corresponding RawSubcommand
    static func from(_ streamType: RawStreamType) -> RawSubcommand {
        switch streamType {
        case .blood: return .startBlood
        case .heartRateSensor: return .startHeartRateSensor
        case .accelerometer: return .startAccelerometer
        }
    }
}
