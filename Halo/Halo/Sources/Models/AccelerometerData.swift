/// Represents accelerometer sensor data from the ring device
struct AccelerometerData {
    /// X-axis acceleration in g-force units (processed)
    let x: Float
    
    /// Y-axis acceleration in g-force units (processed)
    let y: Float
    
    /// Z-axis acceleration in g-force units (processed)
    let z: Float
    
    /// Raw X-axis accelerometer reading (unprocessed sensor value)
    let rawX: Int
    
    /// Raw Y-axis accelerometer reading (unprocessed sensor value)
    let rawY: Int
    
    /// Raw Z-axis accelerometer reading (unprocessed sensor value)
    let rawZ: Int
}
