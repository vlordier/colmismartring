//
//  RingSessionManager.swift
//  Halo
//
//  Created by Yannis De Cleene on 27/01/2025.
//

import AccessorySetupKit
import CoreBluetooth
import Foundation
import SwiftUI

/// Manages Bluetooth communication with the ring device
///
/// This class handles all aspects of connecting to and communicating with the ring:
/// - Device discovery and pairing
/// - Bluetooth connection management
/// - Command transmission and response handling
/// - Real-time data streaming
/// - Historical data retrieval
@Observable
class RingSessionManager: NSObject {
    /// Indicates if a Bluetooth connection is currently established
    var peripheralConnected = false

    /// Tracks the state of the accessory picker UI
    var pickerDismissed = true

    /// Currently connected ring accessory
    var currentRing: ASAccessory?

    /// Session manager for accessory setup and pairing
    private var session = ASAccessorySession()

    /// Bluetooth central manager for scanning and connecting
    private var manager: CBCentralManager?

    /// Connected Bluetooth peripheral (ring device)
    private var peripheral: CBPeripheral?

    /// Characteristic for sending commands to the ring
    private var uartRxCharacteristic: CBCharacteristic?

    /// Characteristic for receiving data from the ring
    private var uartTxCharacteristic: CBCharacteristic?

    /// UUID for the ring's main UART service
    private static let ringServiceUUID = "6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E"

    /// UUID for sending commands to the ring (write characteristic)
    private static let uartRxCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

    /// UUID for receiving data from the ring (notify characteristic)
    private static let uartTxCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

    /// UUID for the standard Bluetooth device information service
    private static let deviceInfoServiceUUID = "0000180A-0000-1000-8000-00805F9B34FB"

    /// UUID for hardware revision characteristic
    private static let deviceHardwareUUID = "00002A27-0000-1000-8000-00805F9B34FB"

    /// UUID for firmware revision characteristic
    private static let deviceFirmwareUUID = "00002A26-0000-1000-8000-00805F9B34FB"

    /// Command to make the ring's LED blink twice (0x10)
    /// Used for testing connectivity
    private static let CMD_BLINK_TWICE: UInt8 = 16

    /// Command to request battery status (0x03)
    /// Returns battery level and charging state
    private static let CMD_BATTERY: UInt8 = 3

    /// Command to read historical heart rate data (0x15)
    /// Returns heart rate measurements for a specified time period
    private static let CMD_READ_HEART_RATE: UInt8 = 21

    /// Command to start real-time sensor readings (0x69)
    /// Used to begin continuous streaming of sensor data
    private static let CMD_START_REAL_TIME: UInt8 = 105

    /// Command to stop real-time sensor readings (0x6A)
    /// Used to end continuous streaming of sensor data
    private static let CMD_STOP_REAL_TIME: UInt8 = 106
    
    /// Command to get step count data for a specific day (0x43)
    private static let CMD_GET_STEP_SOMEDAY: UInt8 = 67

    private let hrp = HeartRateLogParser()
    private let sportParser = SportDetailParser()
    private let healthKitService = HealthKitService()
    
    @AppStorage("lastConnectedDevice") private var lastDeviceID: String?
    @AppStorage("lastSyncDate") private var lastSyncDate: Date?

    private static let ring: ASPickerDisplayItem = {
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = CBUUID(string: ringServiceUUID)

        return ASPickerDisplayItem(
            name: "COLMI R02 Ring",
            productImage: UIImage(named: "colmi")!,
            descriptor: descriptor
        )
    }()

    private var characteristicsDiscovered = false

    var batteryStatusCallback: ((BatteryInfo) -> Void)?
    var heartRateLogCallback: ((HeartRateLog) -> Void)?
    var stepLogCallback: ((StepLog) -> Void)?

    override init() {
        super.init()
        session.activate(on: DispatchQueue.main, eventHandler: handleSessionEvent(event:))
    }

    // MARK: - RingSessionManager actions

    func presentPicker() {
        session.showPicker(for: [Self.ring]) { error in
            if let error {
                print("Failed to show picker due to: \(error.localizedDescription)")
            }
        }
    }

    func removeRing() {
        guard let currentRing else { return }

        if peripheralConnected {
            disconnect()
        }

        session.removeAccessory(currentRing) { _ in
            self.currentRing = nil
            self.manager = nil
        }
    }

    func connect() {
        guard
            let manager, manager.state == .poweredOn,
            let peripheral
        else {
            return
        }
        let options: [String: Any] = [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionStartDelayKey: 1,
        ]
        manager.connect(peripheral, options: options)
    }

    func disconnect() {
        guard let peripheral, let manager else { return }
        manager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - ASAccessorySession functions

    private func saveRing(ring: ASAccessory) {
        currentRing = ring

        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    private func handleSessionEvent(event: ASAccessoryEvent) {
        switch event.eventType {
        case .accessoryAdded, .accessoryChanged:
            guard let ring = event.accessory else { return }
            saveRing(ring: ring)
        case .activated:
            guard let ring = session.accessories.first else { return }
            saveRing(ring: ring)
        case .accessoryRemoved:
            currentRing = nil
            manager = nil
        case .pickerDidPresent:
            pickerDismissed = false
        case .pickerDidDismiss:
            pickerDismissed = true
        default:
            print("Received event type \(event.eventType)")
        }
    }
}

// MARK: - Step Tracking
extension RingSessionManager {
    func getStepLog(dayOffset: Int = 0, completion: @escaping (StepLog) -> Void) {
        guard let uartRxCharacteristic, let peripheral else {
            print("Cannot send step request. Peripheral or characteristic not ready.")
            return
        }

        do {
            let packet = try makeStepPacket(dayOffset: dayOffset)
            let data = Data(packet)
            peripheral.writeValue(data, for: uartRxCharacteristic, type: .withResponse)
            
            stepLogCallback = completion
            sportParser.reset()
        } catch {
            print("Failed to create step packet: \(error)")
        }
    }
    
    private func makeStepPacket(dayOffset: Int) throws -> [UInt8] {
        var subData: [UInt8] = [UInt8(dayOffset), 0x0F, 0x00, 0x5F, 0x01]
        return try makePacket(command: Self.CMD_GET_STEP_SOMEDAY, subData: subData)
    }
    
    private func handleStepResponse(packet: [UInt8]) {
        guard packet[0] == Self.CMD_GET_STEP_SOMEDAY else { return }
        
        let result = sportParser.parse(packet: packet)
        
        switch result {
        case .complete(let details):
            let log = StepLog(
                date: Date(), 
                details: details,
                totalSteps: details.reduce(0) { $0 + $1.steps }
            )
            stepLogCallback?(log)
            stepLogCallback = nil
            
        case .noData:
            stepLogCallback?(StepLog.empty)
            stepLogCallback = nil
            
        case .partial, .none:
            break // Still receiving data
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension RingSessionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager state: \(central.state)")
        switch central.state {
        case .poweredOn:
            if let peripheralUUID = currentRing?.bluetoothIdentifier {
                if let knownPeripheral = central.retrievePeripherals(withIdentifiers: [peripheralUUID]).first {
                    print("Found previously connected peripheral")
                    peripheral = knownPeripheral
                    peripheral?.delegate = self
                    connect()
                } else {
                    print("Known peripheral not found, starting scan")
                }
            }
        default:
            peripheral = nil
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("DEBUG: Connected to peripheral: \(peripheral)")
        peripheral.delegate = self
        print("DEBUG: Discovering services...")
        peripheral.discoverServices([CBUUID(string: Self.ringServiceUUID), CBUUID(string: Self.deviceInfoServiceUUID)])

        peripheralConnected = true
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: (any Error)?
    ) {
        print("Disconnected from peripheral: \(peripheral)")
        peripheralConnected = false
        characteristicsDiscovered = false
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        print("Failed to connect to peripheral: \(peripheral), error: \(error.debugDescription)")
    }
}

// MARK: - CBPeripheralDelegate

extension RingSessionManager: CBPeripheralDelegate {
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: (any Error)?
    ) {
        print("DEBUG: Services discovery callback, error: \(String(describing: error))")
        guard error == nil, let services = peripheral.services else {
            print("DEBUG: No services found or error occurred")
            return
        }

        print("DEBUG: Found \(services.count) services")
        for service in services {
            switch service.uuid {
            case CBUUID(string: Self.ringServiceUUID):
                print("DEBUG: Found ring service, discovering characteristics...")
                peripheral.discoverCharacteristics([
                    CBUUID(string: Self.uartRxCharacteristicUUID),
                    CBUUID(string: Self.uartTxCharacteristicUUID),
                ], for: service)
            case CBUUID(string: Self.deviceInfoServiceUUID):
                print("DEBUG: Found device info service")
            default:
                break
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        print("DEBUG: Characteristics discovery callback, error: \(String(describing: error))")
        guard error == nil,
              let characteristics = service.characteristics
        else {
            print("DEBUG: No characteristics found or error occurred")
            return
        }

        print("DEBUG: Found \(characteristics.count) characteristics")
        for characteristic in characteristics {
            switch characteristic.uuid {
            case CBUUID(string: Self.uartRxCharacteristicUUID):
                print("DEBUG: Found UART RX characteristic")
                uartRxCharacteristic = characteristic
            case CBUUID(string: Self.uartTxCharacteristicUUID):
                print("DEBUG: Found UART TX characteristic")
                uartTxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                print("DEBUG: Found other characteristic: \(characteristic.uuid)")
            }
        }
        characteristicsDiscovered = true
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value else {
            print("Failed to read characteristic value: \(String(describing: error))")
            return
        }

        let packet = [UInt8](value)

        switch packet[0] {
        case RingSessionManager.CMD_BATTERY:
            handleBatteryResponse(packet: packet)
        case RingSessionManager.CMD_READ_HEART_RATE:
            handleHeartRateLogResponse(packet: packet)
        case RingSessionManager.CMD_GET_STEP_SOMEDAY:
            handleStepResponse(packet: packet)
        case Counter.shared.CMD_X:
            print("🔥")
        case RingSessionManager.CMD_START_REAL_TIME:
            let readingType = RealTimeReading(rawValue: packet[1]) ?? .heartRate
            let errorCode = packet[2]

            if errorCode == 0 && readingType == .heartRate {
                let bpm = Double(packet[3])
                healthKitService.saveHeartRate(bpm, date: Date()) { success in
                    print("HealthKit save \(success ? "succeeded" : "failed")")
                }
            } else {
                print("Error in reading - Type: \(readingType), Error Code: \(errorCode)")
            }
        default:
            break
        }

        if characteristic.uuid == CBUUID(string: Self.uartTxCharacteristicUUID) {
            if let value = characteristic.value {
                print("Received value: \(value) : \([UInt8](value))")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("Write to characteristic failed: \(error.localizedDescription)")
        } else {
            print("Write to characteristic successful")
        }
    }
}

// MARK: - BlinkTwice

extension RingSessionManager {
    func sendBlinkTwiceCommand() {
        do {
            let blinkTwicePacket = try makePacket(command: RingSessionManager.CMD_BLINK_TWICE, subData: nil)
            sendPacket(packet: blinkTwicePacket)
        } catch {
            print("Failed to create blink twice packet: \(error)")
        }
    }

    private func sendPacket(packet: [UInt8]) {
        guard let uartRxCharacteristic, let peripheral else {
            print("Cannot send packet. Peripheral or characteristic not ready.")
            return
        }

        let data = Data(packet)
        peripheral.writeValue(data, for: uartRxCharacteristic, type: .withResponse)
    }
}

// MARK: - RealTime Streaming

/// Extension handling real-time sensor data streaming from the ring
/// Supports multiple sensor types (heart rate, SPO2, etc.) with continuous data updates
extension RingSessionManager {
    /// Initiates real-time streaming for a specific sensor type
    ///
    /// The ring device will begin sending continuous updates for the requested sensor.
    /// Data packets will be received through the characteristic update delegate method.
    ///
    /// Packet Format:
    /// - Byte 0: CMD_START_REAL_TIME (105)
    /// - Byte 1: Sensor type (heart rate, SPO2, etc.)
    /// - Byte 2: Action (1 = start)
    /// - Byte 3-15: Reserved
    ///
    /// Response Format:
    /// - Byte 0: CMD_START_REAL_TIME (105)
    /// - Byte 1: Sensor type
    /// - Byte 2: Error code (0 = success)
    /// - Byte 3: Current sensor value
    /// - Byte 4-15: Reserved
    ///
    /// - Parameter type: The type of sensor reading to stream (heart rate, SPO2, etc.)
    func startRealTimeStreaming(type: RealTimeReading) {
        sendRealTimeCommand(command: RingSessionManager.CMD_START_REAL_TIME, type: type, action: .start)
    }

    /// Continues an active real-time streaming session
    ///
    /// Sends a continuation packet to maintain the streaming connection.
    /// This prevents the ring from timing out the streaming session.
    ///
    /// - Parameter type: The type of sensor currently being streamed
    func continueRealTimeStreaming(type: RealTimeReading) {
        sendRealTimeCommand(command: RingSessionManager.CMD_START_REAL_TIME, type: type, action: .continue)
    }

    /// Stops real-time streaming for a specific sensor type
    ///
    /// Sends a command to the ring to stop sending continuous updates.
    /// This frees up the connection for other commands.
    ///
    /// Packet Format:
    /// - Byte 0: CMD_STOP_REAL_TIME (106)
    /// - Byte 1: Sensor type
    /// - Byte 2-15: Reserved
    ///
    /// - Parameter type: The type of sensor to stop streaming
    func stopRealTimeStreaming(type: RealTimeReading) {
        sendRealTimeCommand(command: RingSessionManager.CMD_STOP_REAL_TIME, type: type, action: nil)
    }

    /// Sends a real-time command packet to the ring device
    ///
    /// This internal method handles the creation and transmission of real-time
    /// command packets for starting, continuing, or stopping sensor streams.
    ///
    /// - Parameters:
    ///   - command: The command type (start=105 or stop=106)
    ///   - type: The sensor type to control
    ///   - action: Optional action parameter (start=1, continue=3, or nil for stop)
    private func sendRealTimeCommand(command: UInt8, type: RealTimeReading, action: Action?) {
        guard let uartRxCharacteristic, let peripheral else {
            print("Cannot send real-time command. Peripheral or characteristic not ready.")
            return
        }

        var packetData: [UInt8] = [type.rawValue]
        if let action {
            packetData.append(action.rawValue)
        } else {
            packetData.append(contentsOf: [0, 0])
        }

        do {
            let packet = try makePacket(command: command, subData: packetData)
            let data = Data(packet)
            peripheral.writeValue(data, for: uartRxCharacteristic, type: .withResponse)
        } catch {
            print("Failed to create packet: \(error)")
        }
    }
}

// MARK: - Battery Status

extension RingSessionManager {
    func getBatteryStatus(completion: @escaping (BatteryInfo) -> Void) {
        guard let uartRxCharacteristic, let peripheral else {
            print("Cannot send battery request. Peripheral or characteristic not ready.")
            return
        }

        do {
            let packet = try makePacket(command: RingSessionManager.CMD_BATTERY)
            let data = Data(packet)
            peripheral.writeValue(data, for: uartRxCharacteristic, type: .withResponse)

            // Store completion handler to call when data is received
            batteryStatusCallback = completion
        } catch {
            print("Failed to create battery packet: \(error)")
        }
    }

    private func handleBatteryResponse(packet: [UInt8]) {
        guard packet[0] == RingSessionManager.CMD_BATTERY else {
            print("Invalid battery packet received.")
            return
        }

        let batteryLevel = Int(packet[1])
        let charging = packet[2] != 0
        let batteryInfo = BatteryInfo(batteryLevel: batteryLevel, charging: charging)

        // Trigger stored callback with battery info
        batteryStatusCallback?(batteryInfo)
        batteryStatusCallback = nil
    }
}

// MARK: - Heart Rate Log

extension RingSessionManager {
    func getHeartRateLog(completion: @escaping (HeartRateLog) -> Void) {
        guard let uartRxCharacteristic, let peripheral else {
            print("Cannot send heart rate log request. Peripheral or characteristic not ready.")
            return
        }

        do {
            guard let today = startOfDay(for: Date.now) else {
                return
            }
            let target = today.convertToTimeZone(initTimeZone: .gmt, timeZone: .current)

            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: target) else {
                return
            }

            let packet = try readXPacket(for: target)
            let data = Data(packet)
            peripheral.writeValue(data, for: uartRxCharacteristic, type: .withResponse)

            print("HRL Commmand Sent")

            // Store completion handler to call when data is received
            heartRateLogCallback = completion
        } catch {
            print("Failed to create hrl packet: \(error)")
        }
    }

    private func handleHeartRateLogResponse(packet: [UInt8]) {
//        guard packet[0] == RingSessionManager.CMD_READ_HEART_RATE else {
//            print("Invalid heart rate log packet received.")
//            return
//        }

        guard packet[0] == Counter.shared.CMD_X else {
            print("Invalid heart rate log packet received.")
            return
        }

        guard let log = hrp.parse(packet: packet) as? HeartRateLog else {
            return
        }
        heartRateLogCallback?(log)
        heartRateLogCallback = nil
    }
}

// MARK: - X

extension RingSessionManager {
    func sendXCommand() {
        do {
            let xPacket = try makePacket(command: Counter.shared.CMD_X, subData: nil)
            sendPacket(packet: xPacket)
        } catch {
            print("Failed to create blink twice packet: \(error)")
        }
    }
}
