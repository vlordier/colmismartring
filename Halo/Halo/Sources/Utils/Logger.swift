import Foundation
import os.log

/// Centralized logging system for the Halo app
enum Logger {
    /// Categories of logs for different parts of the system
    private enum Category: String {
        case bluetooth = "Bluetooth"
        case healthKit = "HealthKit"
        case heartRate = "HeartRate"
        case device = "Device"
        case general = "General"
    }
    
    /// Log levels for different severity of messages
    private enum Level: String {
        case debug = "🔍"
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
        case critical = "🚨"
    }
    
    /// System logger instances for each category
    private static let loggers: [Category: OSLog] = [
        .bluetooth: OSLog(subsystem: "com.halo.ring", category: Category.bluetooth.rawValue),
        .healthKit: OSLog(subsystem: "com.halo.ring", category: Category.healthKit.rawValue),
        .heartRate: OSLog(subsystem: "com.halo.ring", category: Category.heartRate.rawValue),
        .device: OSLog(subsystem: "com.halo.ring", category: Category.device.rawValue),
        .general: OSLog(subsystem: "com.halo.ring", category: Category.general.rawValue)
    ]
    
    // MARK: - Bluetooth Logging
    
    static func bluetoothDebug(_ message: String) {
        log(.bluetooth, .debug, message)
    }
    
    static func bluetoothInfo(_ message: String) {
        log(.bluetooth, .info, message)
    }
    
    static func bluetoothWarning(_ message: String) {
        log(.bluetooth, .warning, message)
    }
    
    static func bluetoothError(_ message: String) {
        log(.bluetooth, .error, message)
    }
    
    // MARK: - HealthKit Logging
    
    static func healthKitDebug(_ message: String) {
        log(.healthKit, .debug, message)
    }
    
    static func healthKitInfo(_ message: String) {
        log(.healthKit, .info, message)
    }
    
    static func healthKitWarning(_ message: String) {
        log(.healthKit, .warning, message)
    }
    
    static func healthKitError(_ message: String) {
        log(.healthKit, .error, message)
    }
    
    // MARK: - Heart Rate Logging
    
    static func heartRateDebug(_ message: String) {
        log(.heartRate, .debug, message)
    }
    
    static func heartRateInfo(_ message: String) {
        log(.heartRate, .info, message)
    }
    
    static func heartRateWarning(_ message: String) {
        log(.heartRate, .warning, message)
    }
    
    static func heartRateError(_ message: String) {
        log(.heartRate, .error, message)
    }
    
    // MARK: - Device Logging
    
    static func deviceDebug(_ message: String) {
        log(.device, .debug, message)
    }
    
    static func deviceInfo(_ message: String) {
        log(.device, .info, message)
    }
    
    static func deviceWarning(_ message: String) {
        log(.device, .warning, message)
    }
    
    static func deviceError(_ message: String) {
        log(.device, .error, message)
    }
    
    // MARK: - Private Helper Methods
    
    private static func log(_ category: Category, _ level: Level, _ message: String) {
        guard let logger = loggers[category] else { return }
        
        let formattedMessage = "\(level.rawValue) [\(category.rawValue)] \(message)"
        
        switch level {
        case .debug:
            os_log(.debug, log: logger, "%{public}@", formattedMessage)
        case .info:
            os_log(.info, log: logger, "%{public}@", formattedMessage)
        case .warning:
            os_log(.error, log: logger, "%{public}@", formattedMessage)
        case .error, .critical:
            os_log(.fault, log: logger, "%{public}@", formattedMessage)
        }
        
        #if DEBUG
        print(formattedMessage)
        #endif
    }
}
