import AccessorySetupKit
import CoreBluetooth
import SwiftUI

/// View model managing the ring device's data and state
///
/// This class serves as the interface between the UI and the ring device,
/// handling all device-related operations and data management including:
/// - Device discovery and pairing
/// - Battery status monitoring
/// - Heart rate data collection
/// - Error handling
final class RingViewModel: ObservableObject {
    /// The session manager handling direct communication with the ring
    @Published private(set) var ringSessionManager: RingSessionManager
    
    /// Current battery status of the ring device
    @Published var batteryInfo: BatteryInfo?
    
    /// Array of heart rate measurements with timestamps
    @Published var heartRateData: [HeartRateDataPoint] = []
    
    /// Most recent error encountered during device operations
    @Published var lastError: Error?
    
    /// Available rings discovered during scanning
    @Published var discoveredRings: [DiscoveredRing] = []
    
    /// Whether currently scanning for rings
    @Published var isScanning = false

    /// Creates a new RingViewModel instance
    /// - Parameter ringSessionManager: The session manager to use, defaults to a new instance
    init(ringSessionManager: RingSessionManager = RingSessionManager()) {
        self.ringSessionManager = ringSessionManager
    }
    
    /// Start scanning for available rings
    func startScanning() {
        isScanning = true
        discoveredRings = []
        ringSessionManager.presentPicker()
    }
    
    /// Stop scanning for rings
    func stopScanning() {
        isScanning = false
        ringSessionManager.removeRing()
    }
    
    /// Connect to a specific ring
    /// - Parameter ring: The accessory representing the ring to connect to
    func connect(to ring: ASAccessory) {
        stopScanning()
        ringSessionManager.connect()
    }

    /// Requests the current battery status from the ring device
    ///
    /// Updates the `batteryInfo` property when the status is received
    func getBatteryStatus() {
        ringSessionManager.getBatteryStatus { [weak self] info in
            self?.batteryInfo = info
        }
    }

    /// Retrieves the heart rate log from the ring device
    ///
    /// This function fetches historical heart rate data and processes it
    /// on the main thread to update the UI
    func getHeartRateLog() {
        ringSessionManager.getHeartRateLog { [weak self] hrl in
            if Thread.isMainThread {
                self?.handleHeartRateResult(hrl)
            } else {
                DispatchQueue.main.async {
                    self?.handleHeartRateResult(hrl)
                }
            }
        }
    }

    /// Processes the heart rate log data and updates the view model's state
    ///
    /// - Parameter hrl: The heart rate log to process
    private func handleHeartRateResult(_ hrl: HeartRateLog) {
        do {
            let heartRatesWithTimes = try hrl.heartRatesWithTimes()
            self.heartRateData = heartRatesWithTimes.map {
                HeartRateDataPoint(heartRate: $0.0, time: $0.1)
            }
            Logger.heartRateInfo("Processed \(heartRatesWithTimes.count) heart rate readings")
        } catch {
            Logger.heartRateError("Failed to process heart rate log: \(error.localizedDescription)")
            self.lastError = error
        }
    }
}
