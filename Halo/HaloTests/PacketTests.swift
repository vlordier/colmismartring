//
//  PacketTests.swift
//  HaloTests
//

import XCTest
@testable import Halo

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
        let packet: [UInt8] = [0x15, 0x01, 0x02, 0x03]
        
        // When
        let result = checksum(packet: packet)
        
        // Then
        XCTAssertEqual(result, 0x1B) // 0x15 + 0x01 + 0x02 + 0x03 = 0x1B
    }
}
