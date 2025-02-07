//
//  BluetoothService.swift
//  Halo
//

import CoreBluetooth
import Foundation

protocol BluetoothServiceDelegate: AnyObject {
    func bluetoothService(_ service: BluetoothService, didReceivePacket packet: [UInt8])
    func bluetoothService(_ service: BluetoothService, didChangeConnectionState connected: Bool)
    func bluetoothService(_ service: BluetoothService, didReceiveError error: Error)
}

final class BluetoothService: NSObject {
    weak var delegate: BluetoothServiceDelegate?

    // MARK: - Properties

    private var manager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var uartRxCharacteristic: CBCharacteristic?
    private var uartTxCharacteristic: CBCharacteristic?

    // MARK: - Constants

    private static let ringServiceUUID = "6E40FFF0-B5A3-F393-E0A9-E50E24DCCA9E"
    private static let uartRxCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
    private static let uartTxCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    func connect(to peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        manager?.connect(peripheral, options: nil)
    }

    func disconnect() {
        guard let peripheral else { return }
        manager?.cancelPeripheralConnection(peripheral)
    }

    func sendPacket(_ packet: [UInt8]) {
        guard let characteristic = uartRxCharacteristic,
              let peripheral else { return }
        let data = Data(packet)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Ready for use
        }
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
        guard let value = characteristic.value else { return }
        delegate?.bluetoothService(self, didReceivePacket: [UInt8](value))
    }
}
