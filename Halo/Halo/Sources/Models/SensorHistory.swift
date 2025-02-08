import Foundation
import simd

struct SensorHistory {
    var heartRate: [Double] = []
    var spo2: [Double] = []
    var accelerometer: [SIMD3<Double>] = []
    var rawAccelerometer: [SIMD3<Int>] = []
    var rawBlood: [Double] = []
    var maxValues: [[Double]] = [[], [], []]
    var hrsData: [Int] = []
    
    mutating func add(_ data: SensorData) {
        let maxPoints = 500
        
        if let hr = data.heartRate {
            heartRate.append(Double(hr))
            heartRate = Array(heartRate.suffix(maxPoints))
        }
        
        if let sp = data.spo2 {
            spo2.append(Double(sp))
            spo2 = Array(spo2.suffix(maxPoints))
        }
        
        if let accel = data.accelerometer {
            let vector = SIMD3(
                Double(accel.x), 
                Double(accel.y),
                Double(accel.z)
            )
            accelerometer.append(vector)
            accelerometer = Array(accelerometer.suffix(maxPoints))
        }
        
        if let raw = data.rawBlood {
            rawBlood.append(Double(raw))
            rawBlood = Array(rawBlood.suffix(maxPoints))
            
            if let m1 = data.max1, let m2 = data.max2, let m3 = data.max3 {
                maxValues[0].append(Double(m1))
                maxValues[1].append(Double(m2))
                maxValues[2].append(Double(m3))
                
                maxValues = maxValues.map { Array($0.suffix(maxPoints)) }
            }
        }
    }
}
