import Foundation

struct SensorData: Codable {
    let timestamp: Date
    let heartRate: Int?
    let spo2: Int?
    let accelerometer: AccelerometerData?
    let ppg: Int?
    let batteryLevel: Int?
    let rawBlood: Int?
    let max1: Int?
    let max2: Int?
    let max3: Int?
    let hrsData: Bool?
    
    struct AccelerometerData: Codable {
        let x: Float
        let y: Float
        let z: Float
        let rawX: Int?
        let rawY: Int?
        let rawZ: Int?
    }
}
