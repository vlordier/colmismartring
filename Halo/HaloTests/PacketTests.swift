//
//  PacketTests.swift
//  HaloTests
//

@testable import Halo
import XCTest

final class PacketTests: XCTestCase {
    func testMakePacket() throws {
        // Given
        let command: UInt8 = 0x15
        let subData: [UInt8] = [0x01, 0x02, 0x03]

        // When
        let packet = try makePacket(command: command, subData: subData)

        // Then
        XCTAssertEqual(packet.count, 16)
        XCTAssertEqual(packet[0], command)
        XCTAssertEqual(packet[1], 0x01)
        XCTAssertEqual(packet[2], 0x02)
        XCTAssertEqual(packet[3], 0x03)
    }

    func testMakePacketWithoutSubData() throws {
        // Given
        let command: UInt8 = 0x15

        // When
        let packet = try makePacket(command: command)

        // Then
        XCTAssertEqual(packet.count, 16)
        XCTAssertEqual(packet[0], command)
    }

    func testChecksumCalculation() {
        // Given
        var packet = [UInt8](repeating: 0x00, count: 16)
        packet[0] = 0x15
        packet[1] = 0x01
        packet[2] = 0x02
        packet[3] = 0x03

        // When
        let result = checksum(packet: packet)

        // Then
        // Sum of all 15 bytes (0x15 + 0x01 + 0x02 + 0x03 + 11 zeros) = 0x1B
        let expectedSum = [0x15, 0x01, 0x02, 0x03] + Array(repeating: 0x00, count: 11)
        XCTAssertEqual(result, expectedSum.reduce(0, +) % 255)
    }
    
    func testSensorDataParsing() {
        // Test SpO2 data
        let spo2Data: [UInt8] = [0xA1, 0x01, 0x12, 0x34, 0x00, 0x56, 0x00, 0x78, 0x00, 0x9A]
        let spo2Result = BluetoothService().parseSensorData(spo2Data)
        XCTAssertEqual(spo2Result["spO2"], 0x1234)
        XCTAssertEqual(spo2Result["spO2_max"], 0x56)
        XCTAssertEqual(spo2Result["spO2_min"], 0x78)
        XCTAssertEqual(spo2Result["spO2_diff"], 0x9A)

        // Test PPG data
        let ppgData: [UInt8] = [0xA1, 0x02, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99]
        let ppgResult = BluetoothService().parseSensorData(ppgData)
        XCTAssertEqual(ppgResult["ppg"], 0x1122)
        XCTAssertEqual(ppgResult["ppg_max"], 0x3344)
        XCTAssertEqual(ppgResult["ppg_min"], 0x5566)
        XCTAssertEqual(ppgResult["ppg_diff"], 0x7788)

        // Test Accelerometer data
        let accData: [UInt8] = [0xA1, 0x03, 0x8F, 0x0F, 0x4F, 0x0F, 0x8F, 0x0F, 0x00, 0x00]
        let accResult = BluetoothService().parseSensorData(accData)
        XCTAssertEqual(accResult["accY"], -0x71)  // 0x8F0F (two's complement)
        XCTAssertEqual(accResult["accZ"], 0x4F0F)
        XCTAssertEqual(accResult["accX"], -0x71)
    }

    func testZeroValueFiltering() {
        let zeroData: [UInt8] = [0xA1, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let result = BluetoothService().parseSensorData(zeroData)
        XCTAssertTrue(result.isEmpty)
    }
}
