import HealthKit

class HealthKitService {
    private let healthStore = HKHealthStore()
    private var heartRateType: HKQuantityType?

    init() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard let heartRateType else {
            completion(false)
            return
        }

        healthStore.requestAuthorization(
            toShare: [heartRateType],
            read: [heartRateType]
        ) { success, _ in
            completion(success)
        }
    }

    func saveHeartRate(_ bpm: Double, date: Date, completion: @escaping (Bool) -> Void) {
        guard let heartRateType else {
            completion(false)
            return
        }
        
        let unit = HKUnit.count().unitDivided(by: .minute())
        let quantity = HKQuantity(unit: unit, doubleValue: bpm)
        let sample = HKQuantitySample(
            type: heartRateType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        healthStore.save(sample) { success, error in
            if let error {
                print("Error saving heart rate: \(error.localizedDescription)")
            }
            completion(success)
        }
    }
}
