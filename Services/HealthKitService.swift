import HealthKit

class HealthKitService {
    private let healthStore = HKHealthStore()
    private var heartRateType: HKQuantityType?
    
    init() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let heartRateType = heartRateType else {
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: [heartRateType], 
                                       read: [heartRateType]) { success, _ in
            completion(success)
        }
    }
    
    func saveHeartRate(_ bpm: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let heartRateType = heartRateType,
              let unit = HKUnit(from: "count/min") else {
            completion(false)
            return
        }
        
        let quantity = HKQuantity(quantityType: heartRateType, 
                                doubleValue: bpm, 
                                      unit: unit)
        let sample = HKQuantitySample(type: heartRateType,
                                    quantity: quantity,
                                   start: date,
                                     end: date)
        
        healthStore.save(sample) { success, _ in
            completion(success)
        }
    }
}
