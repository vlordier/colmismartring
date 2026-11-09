//
//  BatteryInfo.swift
//  Halo
//
//  Created by Yannis De Cleene on 26/01/2025.
//

import Foundation

/// Represents the battery status of the ring device
///
/// This structure contains both the current battery level and charging state
/// of the connected ring device. The battery level is reported as a percentage
/// from 0-100.
struct BatteryInfo {
    /// Current battery level as a percentage (0-100)
    let batteryLevel: Int

    /// Whether the device is currently being charged
    /// - true: Device is connected to power and charging
    /// - false: Device is running on battery power
    let charging: Bool
}
