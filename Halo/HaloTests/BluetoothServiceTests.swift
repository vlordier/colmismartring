//
//  BluetoothServiceTests.swift
//  HaloTests
//

import XCTest
import CoreBluetooth
@testable import Halo

final class BluetoothServiceTests: XCTestCase {
    var sut: BluetoothService!
    var mockDelegate: MockBluetoothServiceDelegate!
    
    override func setUp() {
        super.setUp()
        sut = BluetoothService()
        mockDelegate = MockBluetoothServiceDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(sut, "BluetoothService should be initialized")
    }
    
    func testConnectionStateChange() {
        // Given
        let peripheral = MockCBPeripheral()
        
        // When
        sut.connect(to: peripheral)
        
        // Then
        XCTAssertTrue(mockDelegate.connectionStateChanged)
        XCTAssertTrue(mockDelegate.isConnected)
    }
}

// MARK: - Mocks

private class MockBluetoothServiceDelegate: BluetoothServiceDelegate {
    var receivedPackets: [[UInt8]] = []
    var connectionStateChanged = false
    var isConnected = false
    
    func bluetoothService(_ service: BluetoothService, didReceivePacket packet: [UInt8]) {
        receivedPackets.append(packet)
    }
    
    func bluetoothService(_ service: BluetoothService, didChangeConnectionState connected: Bool) {
        connectionStateChanged = true
        isConnected = connected
    }
}

private class MockCBPeripheral: CBPeripheral {
    override var state: CBPeripheralState {
        return .connected
    }
}
