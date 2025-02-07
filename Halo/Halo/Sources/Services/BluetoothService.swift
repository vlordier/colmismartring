//
//  BluetoothService.swift
//  Halo
//

import CoreBluetooth
import Foundation

/// Protocol defining the interface for receiving Bluetooth events and data
protocol BluetoothServiceDelegate: AnyObject {
    /// Called when a data packet is received from the connected device
    /// - Parameters:
    ///   - service: The BluetoothService instance that received the packet
    ///   - packet: Raw data packet as array of bytes
    func bluetoothService(_ service: BluetoothService, didReceivePacket packet: [UInt8])
    
    /// Called when the connection state with the device changes
    /// - Parameters:
    ///   - service: The BluetoothService instance that changed state
    ///   - connected: True if connected, false if disconnected
    func bluetoothService(_ service: BluetoothService, didChangeConnectionState connected: Bool)
    
    /// Called when an error occurs during Bluetooth operations
    /// - Parameters:
    ///   - service: The BluetoothService instance that encountered the error
    ///   - error: The error that occurred
    func bluetoothService(_ service: BluetoothService, didReceiveError error: Error)
    
    /// Called when sensor data is received and parsed
    /// - Parameters:
    ///   - service: The BluetoothService instance that received the data
    ///   - data: Dictionary containing parsed sensor values
    func bluetoothService(_ service: BluetoothService, didReceiveSensorData data: [String: Int])
    
    /// Called when accelerometer data is received
    /// - Parameters:
    ///   - service: The BluetoothService instance that received the data
    ///   - x: X-axis acceleration
    ///   - y: Y-axis acceleration
    ///   - z: Z-axis acceleration
    func bluetoothService(_ service: BluetoothService, didReceiveAccelerometerData x: Float, y: Float, z: Float)
}

/// Service managing Bluetooth communication with the ring device
///
/// This class handles all Bluetooth Low Energy (BLE) operations including:
/// - Device discovery and connection
/// - Data transmission and reception
/// - Connection state management
/// - Error handling
final class BluetoothService: NSObject {
    /// Delegate to receive Bluetooth events and data
    weak var delegate: BluetoothServiceDelegate?
    weak var discoveryDelegate: BluetoothDiscoveryDelegate?

    // MARK: - Properties

    /// Central manager for BLE operations
    private var manager: CBCentralManager?
    
    /// Currently connected peripheral device
    private var peripheral: CBPeripheral?
    
    /// Characteristic for sending data to the device
    private var uartRxCharacteristic: CBCharacteristic?
    
    /// Characteristic for receiving data from the device
    private var uartTxCharacteristic: CBCharacteristic?
    
    /// Whether currently scanning for devices
    private var isScanning = false

    // MARK: - Constants

    /// UUID of the ring's main service
    private static let ringServiceUUID = "6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E"
    
    /// UUID of the characteristic for sending data to the device
    private static let uartRxCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    
    /// UUID of the characteristic for receiving data from the device
    private static let uartTxCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    /// Initiates connection to a discovered peripheral device
    /// - Parameter peripheral: The peripheral device to connect to
    func connect(to peripheral: CBPeripheral) {
        Logger.bluetoothInfo("Connecting to peripheral: \(peripheral.identifier)")
        self.peripheral = peripheral
        peripheral.delegate = self
        manager?.connect(peripheral, options: nil)
    }

    /// Disconnects from the currently connected peripheral
    func disconnect() {
        guard let peripheral else {
            Logger.bluetoothWarning("Attempted to disconnect with no peripheral")
            return
        }
        Logger.bluetoothInfo("Disconnecting from peripheral: \(peripheral.identifier)")
        manager?.cancelPeripheralConnection(peripheral)
    }

    /// Sends a data packet to the connected device
    /// - Parameter packet: Array of bytes to send
    func sendPacket(_ packet: [UInt8]) {
        guard packet.count == 16 else {
            delegate?.bluetoothService(self, didReceiveError: HaloError.invalidPacketLength)
            return
        }
        
        guard let characteristic = uartRxCharacteristic,
              let peripheral else { return }
        let data = Data(packet)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func startRawStream() {
        do {
            let packet = try makePacket(command: PacketCommand.raw.rawValue, subData: [0x04, 0x04])
            sendPacket(packet)
        } catch {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }

    func stopRawStream() {
        do {
            let packet = try makePacket(command: PacketCommand.raw.rawValue, subData: [0x02])
            sendPacket(packet)
        } catch {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            manager?.scanForPeripherals(withServices: [CBUUID(string: Self.ringServiceUUID)])
        } else {
            delegate?.bluetoothService(self, didReceiveError: HaloError.bluetoothUnavailable)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Pass the discovered peripheral directly
        discoveryDelegate?.bluetoothService(self, didDiscover: peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.bluetoothService(self, didChangeConnectionState: true)
        peripheral.discoverServices([CBUUID(string: Self.ringServiceUUID)])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.peripheral = nil
        uartRxCharacteristic = nil
        uartTxCharacteristic = nil
        delegate?.bluetoothService(self, didChangeConnectionState: false)
        if let error {
            delegate?.bluetoothService(self, didReceiveError: error)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.bluetoothService(self, didReceiveError: error ?? NSError(domain: "BluetoothService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect"]))
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil,
              let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([
                CBUUID(string: Self.uartRxCharacteristicUUID),
                CBUUID(string: Self.uartTxCharacteristicUUID),
            ], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil,
              let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            switch characteristic.uuid {
            case CBUUID(string: Self.uartRxCharacteristicUUID):
                uartRxCharacteristic = characteristic
            case CBUUID(string: Self.uartTxCharacteristicUUID):
                uartTxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            delegate?.bluetoothService(self, didReceiveError: error)
            return
        }
        
        guard let value = characteristic.value else {
            delegate?.bluetoothService(self, didReceiveError: NSError(
                domain: "BluetoothService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Empty packet received"]
            ))
            return
        }
        
        let packet = [UInt8](value)
        guard packet.count == 16 else {
            delegate?.bluetoothService(self, didReceiveError: HaloError.invalidPacketLength)
            return
        }
        
        if packet[0] == 0xA1 {
            let sensorData = parseSensorData(packet)
            if !sensorData.isEmpty {
                delegate?.bluetoothService(self, didReceiveSensorData: sensorData)
            }
            return
        }
        
        delegate?.bluetoothService(self, didReceivePacket: packet)
    }
    
    private func parseSensorData(_ data: [UInt8]) -> [String: Int] {
        guard data.count >= 10 else { return [:] }
        
        if data[0] == PacketCommand.raw.rawValue {
            let subtype = data[1]
            var rawValues = [String: Int]()
            
            switch subtype {
            case 0x01:  // Raw blood data
                rawValues["rawBlood"] = Int(data[2]) << 8 | Int(data[3])
                rawValues["max1"] = Int(data[5])
                rawValues["max2"] = Int(data[7])
                rawValues["max3"] = Int(data[9])
                delegate?.bluetoothService(self, didReceiveSensorData: rawValues)
                
            case 0x02:  // HRS data
                delegate?.bluetoothService(self, didReceiveSensorData: ["hrsData": 1])
                
            case 0x03:  // Accelerometer
                let x = Int16(data[2]) << 8 | Int16(data[3])
                let y = Int16(data[4]) << 8 | Int16(data[5])
                let z = Int16(data[6]) << 8 | Int16(data[7])
                delegate?.bluetoothService(self, didReceiveAccelerometerData: Float(x), y: Float(y), z: Float(z))
                
            default:
                break
            }
            return rawValues
        }

        var parsedData: [String: Int] = [
            "payload": 0, "accX": 0, "accY": 0, "accZ": 0,
            "ppg": 0, "ppg_max": 0, "ppg_min": 0, "ppg_diff": 0,
            "spO2": 0, "spO2_max": 0, "spO2_min": 0, "spO2_diff": 0
        ]
        
        // Handle real-time sensor data (command 0x69 = 105)
        if data[0] == 0x69 {
            let sensorType = data[1]
            let errorCode = data[2]
            
            if errorCode == 0 {
                switch sensorType {
                case 11: // Accelerometer X
                    let value = Float(twosComplement(value: Int(data[3]))) / 100.0
                    delegate?.bluetoothService(self, didReceiveAccelerometerData: value, y: 0, z: 0)
                case 12: // Accelerometer Y
                    let value = Float(twosComplement(value: Int(data[3]))) / 100.0
                    delegate?.bluetoothService(self, didReceiveAccelerometerData: 0, y: value, z: 0)
                case 13: // Accelerometer Z
                    let value = Float(twosComplement(value: Int(data[3]))) / 100.0
                    delegate?.bluetoothService(self, didReceiveAccelerometerData: 0, y: 0, z: value)
                default:
                    break
                }
            }
            return parsedData
        }
        
        // Handle standard sensor data packet
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
            return [:]
        }
        
        return parsedData
    }
    
    private func twosComplement(value: Int) -> Int {
        value >= 0x800 ? value - 0x1000 : value
    }
}
