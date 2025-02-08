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
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(Error)
    }
    
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var ringSessionManager: RingSessionManager
    
    /// Current battery status of the ring device
    @Published var batteryInfo: BatteryInfo?
    
    /// Array of heart rate measurements with timestamps
    @Published var heartRateData: [HeartRateDataPoint] = []
    
    /// Queue for retrying failed operations
    private let retryQueue = OperationQueue()

    /// Maximum number of retry attempts
    private let maxRetryAttempts = 3

    /// Current retry attempt count
    @Published private var retryCount = 0

    /// Most recent error encountered during device operations
    @Published var lastError: Error? {
        didSet {
            showError = lastError != nil
        }
    }
    
    /// Whether to show the error alert
    @Published var showError = false

    /// Whether an operation can be retried
    var canRetry: Bool {
        guard let error = lastError as? RetryableError else { return false }
        return error.retryAction != nil && retryCount < maxRetryAttempts
    }
    
    /// Available rings discovered during scanning
    @Published var discoveredRings: [DiscoveredRing] = []
    
    /// Whether currently scanning for rings
    @Published var isScanning = false
    
    /// Current accelerometer readings
    @Published private var rawAccelX: Int = 0
    @Published private var rawAccelY: Int = 0
    @Published private var rawAccelZ: Int = 0
    
    @Published var accelerometerData: (x: Float, y: Float, z: Float) = (0, 0, 0) {
        didSet {
            // Create sensor data entry when accelerometer data changes
            let data = SensorData(
                timestamp: Date(),
                heartRate: nil,
                spo2: nil,
                accelerometer: SensorData.AccelerometerData(
                    x: accelerometerData.x,
                    y: accelerometerData.y,
                    z: accelerometerData.z,
                    rawX: rawAccelX,
                    rawY: rawAccelY,
                    rawZ: rawAccelZ
                ),
                ppg: nil,
                batteryLevel: batteryInfo?.batteryLevel,
                rawBlood: nil,
                max1: nil,
                max2: nil,
                max3: nil,
                hrsData: nil
            )
            currentSensorData = data
            
            // Log the data if logging is enabled
            if isLogging {
                loggingService?.logSensorData(data)
            }
        }
    }
    
    /// Current sensor readings
    @Published var currentSensorData: SensorData?
    
    /// Service for logging sensor data
    @Published var loggingService: LoggingService?
    
    /// Whether currently logging sensor data
    @Published var isRawStreaming = false
    
    @Published var isLogging = false {
        didSet {
            if isLogging {
                startLogging()
            } else {
                stopLogging()
            }
        }
    }
    
    @Published var sensorHistory = SensorHistory()
    
    /// Starts logging sensor data to a file
    private func startLogging() {
        guard let loggingService = loggingService else { return }
        
        // Create initial sensor data entry
        let data = SensorData(
            timestamp: Date(),
            heartRate: nil,
            spo2: nil,
            accelerometer: SensorData.AccelerometerData(
                x: accelerometerData.x,
                y: accelerometerData.y,
                z: accelerometerData.z,
                rawX: rawAccelX,
                rawY: rawAccelY,
                rawZ: rawAccelZ
            ),
            ppg: nil,
            batteryLevel: batteryInfo?.batteryLevel,
            rawBlood: nil,
            max1: nil,
            max2: nil,
            max3: nil,
            hrsData: nil
        )
        
        loggingService.logSensorData(data)
    }
    
    /// Stops logging sensor data
    private func stopLogging() {
        // Clean up any logging resources if needed
    }

    /// Creates a new RingViewModel instance
    /// - Parameter ringSessionManager: The session manager to use, defaults to a new instance
    init(ringSessionManager: RingSessionManager = RingSessionManager()) {
        self.ringSessionManager = ringSessionManager
        self.loggingService = LoggingService()
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
    func refreshCurrentData() {
        getBatteryStatus()
        // Refresh other real-time data
    }
    
    func refreshLastFiveMinutes() {
        // Implement 5-minute refresh
    }
    
    func refreshLastHour() {
        // Implement hourly refresh
    }
    
    func refreshHistoricalData() {
        getHeartRateLog()
    }

    /// Retries the last failed operation
    func retryLastOperation() {
        guard let error = lastError as? RetryableError,
              let retryAction = error.retryAction,
              retryCount < maxRetryAttempts else {
            return
        }
        
        retryCount += 1
        
        // Add delay based on retry count
        let delay = TimeInterval(retryCount) * 2.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            retryAction()
        }
    }

    /// Resets the retry count
    private func resetRetryCount() {
        retryCount = 0
    }

    /// Handles errors from various operations
    private func handleError(_ error: Error) {
        lastError = error
        showError = true
        
        if let haloError = error as? HaloError {
            Logger.deviceError("Device error: \(haloError.localizedDescription)")
            
            // Handle specific error cases
            switch haloError {
            case .deviceDisconnected:
                ringSessionManager.connect()
            case .bluetoothUnavailable:
                // Show settings prompt
                break
            case .healthKitUnauthorized:
                // Show permissions prompt
                break
            default:
                break
            }
        } else {
            Logger.deviceError("Unknown error: \(error.localizedDescription)")
        }
    }
    
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
