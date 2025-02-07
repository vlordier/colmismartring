import Foundation

/// Represents the battery status information of the ring device
struct BatteryInfo {
    /// Current battery level as a percentage (0-100)
    let batteryLevel: Int
    
    /// Whether the device is currently charging
    let charging: Bool
}
