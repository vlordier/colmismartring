import CoreBluetooth

/// Represents the possible connection states of a Bluetooth device
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

/// Protocol defining the core Bluetooth connection management functionality
protocol BluetoothConnectionManager: AnyObject {
    var delegate: BluetoothConnectionManagerDelegate? { get set }
    var connectionState: ConnectionState { get }
    
    func connect(to peripheral: CBPeripheral)
    func disconnect()
    func startScanning()
    func stopScanning()
    func sendPacket(_ packet: [UInt8]) async throws
}

protocol BluetoothConnectionManagerDelegate: AnyObject {
    func connectionManager(_ manager: BluetoothConnectionManager, didUpdateState state: ConnectionState)
    func connectionManager(_ manager: BluetoothConnectionManager, didDiscoverPeripheral peripheral: CBPeripheral)
    func connectionManager(_ manager: BluetoothConnectionManager, didReceivePacket packet: [UInt8])
    func connectionManager(_ manager: BluetoothConnectionManager, didReceiveError error: BluetoothError)
}

/// Default implementation of BluetoothConnectionManager
final class DefaultBluetoothConnectionManager: NSObject, BluetoothConnectionManager {
    // MARK: - Properties and Constants
    
    /// Delegate to receive Bluetooth connection events and state changes
    weak var delegate: BluetoothConnectionManagerDelegate?
    
    /// Current state of the Bluetooth connection (connected, disconnected, etc)
    private(set) var connectionState: ConnectionState = .disconnected
    
    /// Handler responsible for validating and processing incoming Bluetooth packets
    /// Validates packet format, checksums, and processes different packet types
    private let bluetoothPacketValidationHandler: PacketHandler
    
    /// Core Bluetooth central manager for device scanning and connection management
    /// Handles scanning, connecting, and disconnecting from peripherals
    private var bluetoothDeviceManager: CBCentralManager?
    
    /// Currently connected smart ring peripheral device
    /// Represents the physical ring device we're communicating with
    private var connectedSmartRingDevice: CBPeripheral?
    
    /// Characteristic for sending commands to the ring (TX from phone perspective)
    /// Used to write commands and data to the ring device
    private var ringCommandCharacteristic: CBCharacteristic?
    
    /// Characteristic for receiving data from the ring (RX from phone perspective)
    /// Used to receive sensor data and responses from the ring device
    private var ringSensorDataCharacteristic: CBCharacteristic?
    
    /// UUID identifying the ring's main UART service for BLE communication
    /// This is the primary service UUID that identifies compatible ring devices
    private static let smartRingServiceUUID = "6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E"
    
    /// UUID for sending commands to ring (TX characteristic)
    /// Used to identify the characteristic for writing commands
    private static let ringCommandCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    
    /// UUID for receiving data from ring (RX characteristic)
    /// Used to identify the characteristic for receiving sensor data
    private static let ringSensorDataCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    
    // MARK: - Initialization
    
    init(packetHandler: PacketHandler = DefaultPacketHandler()) {
        self.packetHandler = packetHandler
        super.init()
        self.manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    /// Initiates connection to specified ring device
    /// - Parameter peripheral: The ring device peripheral to connect to
    func connect(to peripheral: CBPeripheral) {
        Logger.bluetoothInfo("Initiating connection to ring device: \(peripheral.identifier)")
        self.connectedRingDevice = peripheral
        peripheral.delegate = self
        connectionState = .connecting
        delegate?.connectionManager(self, didUpdateState: .connecting)
        bluetoothCentralManager?.connect(peripheral, options: nil)
    }
    
    /// Disconnects from currently connected ring device
    func disconnect() {
        guard let ringDevice = self.connectedRingDevice else {
            Logger.bluetoothWarning("Attempted to disconnect but no ring device is connected")
            return
        }
        connectionState = .disconnecting
        delegate?.connectionManager(self, didUpdateState: .disconnecting)
        Logger.bluetoothInfo("Disconnecting from ring device: \(ringDevice.identifier)")
        bluetoothCentralManager?.cancelPeripheralConnection(ringDevice)
    }
    
    func startScanning() {
        manager?.scanForPeripherals(withServices: [CBUUID(string: Self.ringServiceUUID)])
    }
    
    func stopScanning() {
        manager?.stopScan()
    }
    
    func sendPacket(_ packet: [UInt8]) async throws {
        guard let characteristic = uartRxCharacteristic,
              let peripheral = self.peripheral else {
            throw BluetoothError.characteristicNotFound
        }
        
        let result = packetHandler.handlePacket(packet)
        switch result {
        case .success:
            let data = Data(packet)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
                // Note: The continuation will be resumed in the CBPeripheralDelegate callback
            }
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension DefaultBluetoothConnectionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            delegate?.connectionManager(self, didReceiveError: .bluetoothUnavailable)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager, 
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        delegate?.connectionManager(self, didDiscoverPeripheral: peripheral)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        connectionState = .connected
        delegate?.connectionManager(self, didUpdateState: .connected)
        peripheral.discoverServices([CBUUID(string: Self.ringServiceUUID)])
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        self.peripheral = nil
        connectionState = .disconnected
        delegate?.connectionManager(self, didUpdateState: .disconnected)
        if let error {
            delegate?.connectionManager(self, didReceiveError: .connectionFailed(error))
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionState = .disconnected
        delegate?.connectionManager(self, didUpdateState: .disconnected)
        delegate?.connectionManager(self, didReceiveError: .connectionFailed(error))
    }
}

// MARK: - CBPeripheralDelegate

extension DefaultBluetoothConnectionManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverServices error: Error?) {
        guard error == nil else {
            delegate?.connectionManager(self, didReceiveError: .serviceUnavailable)
            return
        }
        
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(
                [
                    CBUUID(string: Self.uartRxCharacteristicUUID),
                    CBUUID(string: Self.uartTxCharacteristicUUID)
                ],
                for: service
            )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                   didDiscoverCharacteristicsFor service: CBService,
                   error: Error?) {
        guard error == nil else {
            delegate?.connectionManager(self, didReceiveError: .characteristicNotFound)
            return
        }
        
        service.characteristics?.forEach { characteristic in
            switch characteristic.uuid.uuidString {
            case Self.uartRxCharacteristicUUID:
                uartRxCharacteristic = characteristic
            case Self.uartTxCharacteristicUUID:
                uartTxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                   didUpdateValueFor characteristic: CBCharacteristic,
                   error: Error?) {
        guard error == nil,
              let value = characteristic.value,
              value.count == 16 else {
            delegate?.connectionManager(self, didReceiveError: .invalidPacketLength)
            return
        }
        
        let packet = [UInt8](value)
        let result = packetHandler.handlePacket(packet)
        
        switch result {
        case .success:
            delegate?.connectionManager(self, didReceivePacket: packet)
        case .failure(let error):
            delegate?.connectionManager(self, didReceiveError: error)
        }
    }
}
