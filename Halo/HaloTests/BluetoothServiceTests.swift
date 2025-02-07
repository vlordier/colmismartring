import XCTest
import CoreBluetooth
@testable import Halo

class BluetoothServiceTests: XCTestCase {
    var service: BluetoothService!
    var mockCentral: MockCBCentralManager!
    var mockPeripheral: MockCBPeripheral!
    
    class TestDelegate: BluetoothServiceDelegate {
        var lastError: Error?
        var lastPacket: [UInt8]?
        var connectionState: Bool?
        
        func bluetoothService(_ service: BluetoothService, didReceivePacket packet: [UInt8]) {
            lastPacket = packet
        }
        
        func bluetoothService(_ service: BluetoothService, didChangeConnectionState connected: Bool) {
            connectionState = connected
        }
        
        func bluetoothService(_ service: BluetoothService, didReceiveError error: Error) {
            lastError = error
        }
    }

    override func setUp() {
        super.setUp()
        service = BluetoothService()
        mockCentral = MockCBCentralManager()
        service.manager = mockCentral
        mockPeripheral = MockCBPeripheral()
        service.peripheral = mockPeripheral
    }

    func testConnectionStatePropagation() {
        let delegate = TestDelegate()
        service.delegate = delegate
        
        // Simulate connection
        service.manager(service.manager!, didConnect: mockPeripheral)
        XCTAssertTrue(delegate.connectionState ?? false)
        
        // Simulate disconnection
        service.manager(service.manager!, didDisconnectPeripheral: mockPeripheral, error: nil)
        XCTAssertFalse(delegate.connectionState ?? true)
    }

    func testPacketHandling() {
        let delegate = TestDelegate()
        service.delegate = delegate
        let testData = Data([0x01, 0x02, 0x03])
        
        // Simulate receiving data
        service.peripheral(mockPeripheral, didUpdateValueFor: CBCharacteristic(), error: nil)
        XCTAssertEqual(delegate.lastPacket ?? [], [UInt8](testData))
    }
}

// MARK: - Bluetooth Mocks
class MockCBCentralManager: CBCentralManager {
    override init() {
        super.init(delegate: nil, queue: nil, options: nil)
    }
    
    override func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        (peripheral as? MockCBPeripheral)?.state = .connected
    }
}

class MockCBPeripheral: CBPeripheral {
    override var state: CBPeripheralState {
        get { return _state }
        set { _state = newValue }
    }
    private var _state: CBPeripheralState = .disconnected
    
    override func readValue(for characteristic: CBCharacteristic) {
        let data = Data([0x01, 0x02, 0x03])
        delegate?.peripheral?(self, didUpdateValueFor: characteristic, error: nil)
    }
}
