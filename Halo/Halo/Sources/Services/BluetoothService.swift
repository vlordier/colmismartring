import CoreBluetooth

/// Delegate protocol for receiving Bluetooth service events
protocol BluetoothServiceDelegate: AnyObject {
    /// Called when a packet is received from the device
    func bluetoothService(_ service: BluetoothServiceType, didReceivePacket packet: [UInt8])
    
    /// Called when the connection state changes
    func bluetoothService(_ service: BluetoothServiceType, didChangeConnectionState connected: Bool)
    
    /// Called when an error occurs
    func bluetoothService(_ service: BluetoothServiceType, didReceiveError error: BluetoothError)
    
    /// Called when sensor data is received
    func bluetoothService(_ service: BluetoothServiceType, didReceiveSensorData data: [String: Int])
    
    /// Called when accelerometer data is received
    func bluetoothService(_ service: BluetoothServiceType, didReceiveAccelerometerData data: AccelerometerData)
}

/// Configuration for Bluetooth service parameters
protocol BluetoothServiceConfiguration {
    var ringServiceUUID: String { get }
    var uartRxCharacteristicUUID: String { get }
    var uartTxCharacteristicUUID: String { get }
    var maxRetryAttempts: Int { get }
    var retryDelay: TimeInterval { get }
}

/// Default configuration implementation
final class DefaultBluetoothServiceConfiguration: BluetoothServiceConfiguration {
    let ringServiceUUID = "6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E"
    let uartRxCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    let uartTxCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    let maxRetryAttempts = 3
    let retryDelay: TimeInterval = 2.0
}

// MARK: - Retry Manager

/// Manages retry attempts for Bluetooth operations using exponential backoff with jitter.
private actor RetryManager {
    private let maxAttempts: Int
    private let baseDelay: TimeInterval
    private var currentAttempt = 0
    private let timeout: TimeInterval
    
    init(maxAttempts: Int = 3, 
         baseDelay: TimeInterval = 1.0,
         timeout: TimeInterval = 5.0) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.timeout = timeout
    }
    
    func shouldRetry() -> Bool {
        currentAttempt < maxAttempts
    }
    
    func nextDelay() -> TimeInterval {
        // Exponential backoff with jitter.
        let exponentialDelay = baseDelay * pow(2.0, Double(currentAttempt))
        let jitter = Double.random(in: 0...0.3)
        currentAttempt += 1
        return min(exponentialDelay + jitter, timeout)
    }
    
    func reset() {
        currentAttempt = 0
    }
    
    var hasExceededRetries: Bool {
        currentAttempt >= maxAttempts
    }
}

// MARK: - Errors

/// Represents all possible Bluetooth-related errors
enum BluetoothError: LocalizedError {
    case serviceUnavailable
    case characteristicNotFound
    case invalidState
    case connectionFailed(Error?)
    case writeFailure(Error?)
    case invalidPacketLength
    case checksumMismatch
    case timeout
    case maxRetriesExceeded
    case notConnected
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Bluetooth service is not available"
        case .characteristicNotFound:
            return "Required characteristic not found"
        case .invalidState:
            return "Bluetooth is in invalid state"
        case .connectionFailed(let error):
            return "Connection failed: \(error?.localizedDescription ?? "Unknown error")"
        case .writeFailure(let error):
            return "Write failed: \(error?.localizedDescription ?? "Unknown error")"
        case .invalidPacketLength:
            return "Invalid packet length"
        case .checksumMismatch:
            return "Checksum verification failed"
        case .timeout:
            return "Operation timed out"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .notConnected:
            return "Device is not connected"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .serviceUnavailable:
            return "Please ensure Bluetooth is enabled on your device"
        case .notConnected:
            return "Please reconnect to the device and try again"
        case .maxRetriesExceeded:
            return "Please check the device connection and try again"
        default:
            return "Please try the operation again"
        }
    }
}

// MARK: - Bluetooth Service Protocols

/// Protocol defining the core Bluetooth service functionality
///
/// This protocol provides the interface for:
/// - Device connection management
/// - Data transmission
/// - Stream control
/// - Error handling
protocol BluetoothServiceType: AnyObject {
    /// Delegate for receiving Bluetooth events and data
    var delegate: BluetoothServiceDelegate? { get set }
    
    /// Delegate for device discovery events
    var discoveryDelegate: BluetoothDiscoveryDelegate? { get set }
    
    /// Current connection state
    var connectionState: ConnectionState { get }
    
    /// Connects to a specified peripheral device
    /// - Parameters:
    ///   - peripheral: The peripheral to connect to
    ///   - completion: Called with the result of the connection attempt
    func connect(to peripheral: CBPeripheral, 
                completion: @escaping (Result<Void, BluetoothError>) -> Void)
    
    /// Disconnects from the currently connected device
    func disconnect()
    
    /// Sends a data packet to the connected device
    /// - Parameter packet: The packet to send
    /// - Returns: A result indicating success or failure
    /// - Throws: BluetoothError if the operation fails
    func sendPacket(_ packet: [UInt8]) async throws -> Result<Void, BluetoothError>
    
    /// Starts a raw data stream
    /// - Parameter type: The type of data to stream
    func startRawStream(type: RawStreamType)
    
    /// Stops the current raw data stream
    func stopRawStream()
}

// Add default implementations
extension BluetoothServiceType {
    func startRawStream(type: RawStreamType) { }
    func stopRawStream() { }
}

/// Protocol for receiving Bluetooth service events and data
protocol BluetoothServiceDelegate: AnyObject {
    /// Called when a packet is received from the device
    func bluetoothService(_ service: BluetoothServiceType, didReceivePacket packet: [UInt8])
    
    /// Called when the connection state changes
    func bluetoothService(_ service: BluetoothServiceType, didChangeConnectionState connected: Bool)
    
    /// Called when an error occurs
    func bluetoothService(_ service: BluetoothServiceType, didReceiveError error: BluetoothError)
    
    /// Called when sensor data is received
    func bluetoothService(_ service: BluetoothServiceType, didReceiveSensorData data: [String: Int])
    
    /// Called when accelerometer data is received
    func bluetoothService(_ service: BluetoothServiceType, didReceiveAccelerometerData data: AccelerometerData)
}

// Add default implementations for optional methods
extension BluetoothServiceDelegate {
    func bluetoothService(_ service: BluetoothServiceType, didReceiveSensorData data: [String: Int]) { }
    func bluetoothService(_ service: BluetoothServiceType, didReceiveAccelerometerData data: AccelerometerData) { }
}

// MARK: - Bluetooth Service Implementation

/// Service managing Bluetooth communication with the ring device.
/// This class handles all Bluetooth Low Energy (BLE) operations including:
/// - Device discovery and connection
/// - Data transmission and reception
/// - Connection state management
/// - Error handling
final class BluetoothService: NSObject, BluetoothServiceType {

    // MARK: - Public Properties

    weak var delegate: BluetoothServiceDelegate?
    weak var discoveryDelegate: BluetoothDiscoveryDelegate?
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var isScanning: Bool = false

    // MARK: - Private Properties

    /// The service configuration.
    private let configuration: BluetoothServiceConfiguration
    
    /// Queue for handling data operations.
    private let dataQueue = DispatchQueue(label: "com.halo.bluetooth.data", qos: .userInitiated)
    
    /// A serial queue for Bluetooth events.
    private let queue: DispatchQueue
    
    /// The central manager (must conform to a BluetoothManagerType protocol).
    private var manager: BluetoothManagerType
    
    /// The connected peripheral.
    private var peripheral: CBPeripheral?
    
    /// The characteristic used for sending data.
    private var uartRxCharacteristic: CBCharacteristic?
    
    /// The characteristic used for receiving data.
    private var uartTxCharacteristic: CBCharacteristic?
    
    /// Manages retry attempts when sending packets.
    private let retryManager = RetryManager()
    
    /// Holds a pending write continuation (assumes only one write is in flight).
    private var writeContinuation: CheckedContinuation<Void, Error>?
    
    /// Completion closure for connection requests.
    private var connectCompletion: ((Result<Void, BluetoothError>) -> Void)?

    // MARK: - Initialization

    init(
        configuration: BluetoothServiceConfiguration = DefaultBluetoothServiceConfiguration(),
        queue: DispatchQueue = DispatchQueue(label: "com.halo.bluetooth", qos: .userInitiated),
        manager: BluetoothManagerType = CBCentralManager() // Assumes CBCentralManager conforms to BluetoothManagerType.
    ) {
        self.configuration = configuration
        self.queue = queue
        self.manager = manager
        super.init()
        self.manager.delegate = self
    }
    
    // MARK: - BluetoothServiceType Methods

    func connect(
        to peripheral: CBPeripheral,
        completion: @escaping (Result<Void, BluetoothError>) -> Void
    ) {
        Logger.bluetoothInfo("Connecting to peripheral: \(peripheral.identifier)")
        self.peripheral = peripheral
        peripheral.delegate = self
        self.connectCompletion = completion
        manager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = self.peripheral else {
            Logger.bluetoothWarning("Attempted to disconnect with no peripheral")
            return
        }
        Logger.bluetoothInfo("Disconnecting from peripheral: \(peripheral.identifier)")
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func sendPacket(_ packet: [UInt8]) async -> Result<Void, BluetoothError> {
        do {
            try await sendPacketWithRetry(packet)
            return .success(())
        } catch let error as BluetoothError {
            return .failure(error)
        } catch {
            return .failure(.writeFailure(error))
        }
    }
    
    func startRawStream(type: RawStreamType) {
        do {
            let subcommand = RawSubcommand.from(type)
            // Assumes makePacket(command:subData:) is defined elsewhere.
            let packet = try makePacket(command: PacketCommand.raw.rawValue,
                                        subData: [subcommand.rawValue, 0x04])
            Task {
                let result = await sendPacket(packet)
                if case .failure(let error) = result {
                    self.delegate?.bluetoothService(self, didReceiveError: error)
                }
            }
        } catch {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }
    
    func stopRawStream() {
        do {
            let packet = try makePacket(command: PacketCommand.raw.rawValue, subData: [0x02])
            Task {
                let result = await sendPacket(packet)
                if case .failure(let error) = result {
                    self.delegate?.bluetoothService(self, didReceiveError: error)
                }
            }
        } catch {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }
    
    // MARK: - Private Methods

    private func sendPacketWithRetry(_ packet: [UInt8]) async throws {
        var lastError: Error?
        
        while await retryManager.shouldRetry() {
            do {
                guard packet.count == 16 else {
                    throw BluetoothError.invalidPacketLength
                }
                
                guard let characteristic = uartRxCharacteristic,
                      let peripheral = self.peripheral else {
                    throw BluetoothError.characteristicNotFound
                }
                
                let data = Data(packet)
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    // Store the continuation so that the delegate callback can resume it.
                    self.writeContinuation = continuation
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                }
                
                await retryManager.reset()
                return  // Success!
                
            } catch {
                lastError = error
                // Wait before retrying (exponential backoff).
                let delay = UInt64(await retryManager.nextDelay() * 1_000_000_000)
                try await Task.sleep(nanoseconds: delay)
            }
        }
        
        throw lastError ?? BluetoothError.writeFailure(nil)
    }
    
    /// Example packet maker (you should adjust this to your packet format).
    private func makePacket(command: UInt8, subData: [UInt8]) throws -> [UInt8] {
        var packet = [UInt8]()
        // For example, a packet could be 16 bytes long:
        packet.append(command)
        packet.append(contentsOf: subData)
        // Pad to 15 bytes before adding checksum.
        while packet.count < 15 {
            packet.append(0)
        }
        let cs = checksum(packet: packet + [0]) // Calculate checksum based on your algorithm.
        packet.append(cs)
        guard packet.count == 16 else { throw BluetoothError.invalidPacketLength }
        return packet
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ _) {
        if central.state == .poweredOn {
            isScanning = true
            // Start scanning for peripherals using the service UUID.
            manager.scanForPeripherals(withServices: [CBUUID(string: configuration.ringServiceUUID)])
        } else {
            // Use a BluetoothError rather than HaloError.
            delegate?.bluetoothService(self, didReceiveError: BluetoothError.serviceUnavailable)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // Pass the discovered peripheral to the discovery delegate.
        discoveryDelegate?.bluetoothService(self, didDiscover: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        isConnected = true
        delegate?.bluetoothService(self, didChangeConnectionState: true)
        connectCompletion?(.success(()))
        connectCompletion = nil
        peripheral.discoverServices([CBUUID(string: configuration.ringServiceUUID)])
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        isConnected = false
        self.peripheral = nil
        uartRxCharacteristic = nil
        uartTxCharacteristic = nil
        delegate?.bluetoothService(self, didChangeConnectionState: false)
        if let error = error {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectCompletion?(.failure(.connectionFailed(error)))
        connectCompletion = nil
        delegate?.bluetoothService(self, didReceiveError: error ?? NSError(domain: "BluetoothService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect"]))
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothService: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            delegate?.bluetoothService(self, didReceiveError: error ?? BluetoothError.invalidState)
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(
                [
                    CBUUID(string: configuration.uartRxCharacteristicUUID),
                    CBUUID(string: configuration.uartTxCharacteristicUUID)
                ],
                for: service
            )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            let uuidString = characteristic.uuid.uuidString.uppercased()
            if uuidString == configuration.uartRxCharacteristicUUID.uppercased() {
                uartRxCharacteristic = characteristic
            } else if uuidString == configuration.uartTxCharacteristicUUID.uppercased() {
                uartTxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let error = error {
                self.delegate?.bluetoothService(self, didReceiveError: error)
                return
            }
            
            guard let value = characteristic.value else {
                self.delegate?.bluetoothService(
                    self,
                    didReceiveError: NSError(domain: "BluetoothService",
                                             code: -2,
                                             userInfo: [NSLocalizedDescriptionKey: "Empty packet received"]))
                return
            }
            
            let packet = [UInt8](value)
            guard packet.count == 16 else {
                self.delegate?.bluetoothService(self, didReceiveError: BluetoothError.invalidPacketLength)
                return
            }
            
            // Verify checksum.
            let calculatedChecksum = self.checksum(packet: packet)
            if packet[15] != calculatedChecksum {
                self.delegate?.bluetoothService(self, didReceiveError: BluetoothError.checksumMismatch)
                return
            }
            
            // Process sensor data if applicable.
            if packet[0] == 0xA1 {
                let sensorData = self.parseSensorData(packet)
                if !sensorData.isEmpty {
                    self.delegate?.bluetoothService(self, didReceiveSensorData: sensorData)
                }
            }
            
            self.delegate?.bluetoothService(self, didReceivePacket: packet)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // Resume the pending continuation for write operations.
        if let continuation = writeContinuation {
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume()
            }
            writeContinuation = nil
        }
        
        if let error = error {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }
    
    // MARK: - Parsing Incoming Data
    
    private func parseSensorData(_ data: [UInt8]) -> [String: Int] {
        guard data.count >= 16 else { return [:] }
        
        if data[0] == PacketCommand.raw.rawValue {
            return parseRawData(data)
        }
        return parseStandardSensorData(data)
    }
    
    private func parseRawData(_ data: [UInt8]) -> [String: Int] {
        let subtype = data[1]
        var rawValues = [String: Int]()
        
        switch RawSubcommand(rawValue: subtype) {
        case .startBlood:
            rawValues["rawBlood"] = (Int(data[2]) << 8) | Int(data[3])
            rawValues["max1"] = Int(data[5])
            rawValues["max2"] = Int(data[7])
            rawValues["max3"] = Int(data[9])
            
        case .startHRS:
            rawValues["hrsData"] = (Int(data[2]) << 8) | Int(data[3])
            
        case .startAccel:
            // Combine two bytes into a signed 16-bit integer.
            let rawX = Int(Int16(bitPattern: UInt16(data[2]) << 8 | UInt16(data[3])))
            let rawY = Int(Int16(bitPattern: UInt16(data[4]) << 8 | UInt16(data[5])))
            let rawZ = Int(Int16(bitPattern: UInt16(data[6]) << 8 | UInt16(data[7])))
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.bluetoothService(
                    self,
                    didReceiveAccelerometerData: AccelerometerData(
                        x: Float(rawX) / 100.0,
                        y: Float(rawY) / 100.0,
                        z: Float(rawZ) / 100.0,
                        rawX: rawX,
                        rawY: rawY,
                        rawZ: rawZ
                    )
                )
            }
            
        default:
            break
        }
        return rawValues
    }
    
    private func parseStandardSensorData(_ data: [UInt8]) -> [String: Int] {
        var parsedData: [String: Int] = [
            "payload": 0, "accX": 0, "accY": 0, "accZ": 0,
            "ppg": 0, "ppg_max": 0, "ppg_min": 0, "ppg_diff": 0,
            "spO2": 0, "spO2_max": 0, "spO2_min": 0, "spO2_diff": 0
        ]
        
        // Handle real-time sensor data if the command indicates (e.g., 0x69).
        if data[0] == 0x69 {
            let sensorType = data[1]
            let errorCode = data[2]
            if errorCode == 0 {
                switch sensorType {
                case 11, 12, 13: // Accelerometer X, Y, Z
                    var x: Float = 0, y: Float = 0, z: Float = 0
                    var rawX = 0, rawY = 0, rawZ = 0
                    switch sensorType {
                    case 11:
                        x = Float(twosComplement(value: Int(data[3]))) / 100.0
                        rawX = Int(data[3])
                    case 12:
                        y = Float(twosComplement(value: Int(data[3]))) / 100.0
                        rawY = Int(data[3])
                    case 13:
                        z = Float(twosComplement(value: Int(data[3]))) / 100.0
                        rawZ = Int(data[3])
                    default:
                        break
                    }
                    delegate?.bluetoothService(self, didReceiveAccelerometerData: AccelerometerData(
                        x: x, y: y, z: z,
                        rawX: rawX, rawY: rawY, rawZ: rawZ
                    ))
                default:
                    break
                }
            }
            return parsedData
        }
        
        // Handle standard sensor data packet (example: command 0xA1).
        guard data.count >= 10, data[0] == 0xA1 else {
            return parsedData
        }
        
        let subtype = data[1]
        switch subtype {
        case 0x01:  // SpO2 data
            parsedData["spO2"] = (Int(data[2]) << 8) | Int(data[3])
            parsedData["spO2_max"] = Int(data[5])
            parsedData["spO2_min"] = Int(data[7])
            parsedData["spO2_diff"] = Int(data[9])
        case 0x02:  // PPG data
            parsedData["ppg"] = (Int(data[2]) << 8) | Int(data[3])
            parsedData["ppg_max"] = (Int(data[4]) << 8) | Int(data[5])
            parsedData["ppg_min"] = (Int(data[6]) << 8) | Int(data[7])
            parsedData["ppg_diff"] = (Int(data[8]) << 8) | Int(data[9])
        default:
            break
        }
        
        if parsedData["ppg"] == 0 || parsedData["spO2"] == 0 {
            Logger.deviceInfo("Skipping data with zero ppg/spO2 values")
            [:]
        }
        
        return parsedData
    }
    
    /// Computes the two's complement for a given value.
    private func twosComplement(value: Int) -> Int {
        return value >= 0x800 ? value - 0x1000 : value
    }
}
