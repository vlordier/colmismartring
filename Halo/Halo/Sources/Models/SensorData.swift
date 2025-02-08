import Foundation

/// Represents a complete set of sensor readings from the ring at a specific time
struct SensorData: Codable {
    /// Timestamp when the readings were taken
    let timestamp: Date
    
    /// Heart rate in beats per minute (optional)
    let heartRate: Int?
    
    /// Blood oxygen saturation percentage (optional)
    let spo2: Int?
    
    /// Accelerometer readings in three axes (optional)
    let accelerometer: AccelerometerData?
    
    /// Photoplethysmogram (PPG) raw sensor reading (optional)
    let ppg: Int?
    
    /// Current battery level percentage (optional)
    let batteryLevel: Int?
    
    /// Raw blood flow sensor reading (optional)
    let rawBlood: Int?
    
    /// Maximum value from sensor channel 1 (optional)
    let max1: Int?
    
    /// Maximum value from sensor channel 2 (optional)
    let max2: Int?
    
    /// Maximum value from sensor channel 3 (optional)
    let max3: Int?
    
    /// Heart rate sensor raw data (optional)
    let hrsData: Int?
    
    /// Nested accelerometer data structure
    struct AccelerometerData: Codable {
        /// Processed X-axis acceleration in g-force units
        let x: Float
        
        /// Processed Y-axis acceleration in g-force units
        let y: Float
        
        /// Processed Z-axis acceleration in g-force units
        let z: Float
        
        /// Raw X-axis sensor reading
        let rawX: Int
        
        /// Raw Y-axis sensor reading
        let rawY: Int
        
        /// Raw Z-axis sensor reading
        let rawZ: Int
    }
}
