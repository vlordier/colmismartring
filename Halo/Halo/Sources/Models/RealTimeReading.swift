//
//  RealTimeReading.swift
//  Halo
//
//  Created by Yannis De Cleene on 26/01/2025.
//

import Foundation

/// Represents the different types of real-time sensor readings available from the ring
///
/// Each case corresponds to a specific sensor or measurement type that can be
/// requested in real-time from the ring device. The raw values are used in the
/// communication protocol with the ring.
enum RealTimeReading: UInt8 {
    /// Real-time heart rate monitoring (beats per minute)
    case heartRate = 1

    /// Blood pressure measurement (systolic/diastolic)
    case bloodPressure = 2

    /// Blood oxygen saturation level (percentage)
    case spo2 = 3

    /// Fatigue level assessment
    case fatigue = 4

    /// General health status check
    case healthCheck = 5

    /// Electrocardiogram measurement
    case ecg = 7

    /// Blood pressure wave measurement
    case pressure = 8

    /// Blood glucose level estimation
    case bloodSugar = 9

    /// Heart Rate Variability measurement
    case hrv = 10
}

/// Represents the different control actions for real-time sensor readings
///
/// These actions control the flow of real-time data from the ring device.
/// They are used to start, pause, continue, or stop the data stream for
/// any given sensor type.
enum Action: UInt8 {
    /// Begin real-time data streaming
    case start = 1

    /// Temporarily suspend data streaming
    case pause = 2

    /// Resume previously paused data streaming
    case `continue` = 3

    /// Terminate data streaming
    case stop = 4
}
