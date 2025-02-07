import Foundation
import HealthKit

/// Service class for managing HealthKit interactions
///
/// This class handles all HealthKit-related operations including:
/// - Authorization requests
/// - Heart rate data storage
/// - Health data access
final class HealthKitService: ObservableObject {
    /// The main HealthKit store instance
    private let healthStore = HKHealthStore()
    
    /// Requests authorization to access HealthKit data
    ///
    /// This function requests permission to read and write heart rate data.
    /// The completion handler is called on the main thread with the authorization result.
    ///
    /// - Parameter completion: Closure called with authorization result (true if authorized)
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.healthKitError("HealthKit is not available on this device")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            Logger.healthKitError("Unable to create heart rate type")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        // Request both read and write access for heart rate
        let typesToShare: Set<HKSampleType> = [heartRateType]
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if let error {
                    Logger.healthKitError("HealthKit authorization failed: \(error.localizedDescription)")
                } else {
                    Logger.healthKitInfo("HealthKit authorization successful")
                }
                completion(success)
            }
        }
    }
    
    /// Saves a heart rate measurement to HealthKit
    ///
    /// This function creates a new heart rate sample and saves it to HealthKit.
    /// The completion handler is called on the main thread with the result.
    ///
    /// - Parameters:
    ///   - heartRate: The heart rate value in beats per minute
    ///   - date: The timestamp for the measurement
    ///   - completion: Closure called with save result and any error
    func saveHeartRate(_ heartRate: Double, date: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, nil)
            return
        }
        
        let unit = HKUnit.count().unitDivided(by: .minute())
        let quantity = HKQuantity(unit: unit, doubleValue: heartRate)
        let sample = HKQuantitySample(
            type: heartRateType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}
