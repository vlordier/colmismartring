import XCTest
@testable import Halo

final class HeartRatePacketParserTests: XCTestCase {
    var parser: HeartRatePacketParser!
    var mockTimestampParser: MockTimestampParser!
    
    override func setUp() {
        super.setUp()
        mockTimestampParser = MockTimestampParser()
        parser = HeartRatePacketParser(timestampParser: mockTimestampParser)
    }
    
    func testParseInitializationPacket() {
        // Given
        var packet = [UInt8](repeating: 0, count: 16)
        packet[1] = 0  // Init packet
        packet[2] = 24 // Size
        packet[3] = 5  // Interval
        
        // When
        let result = parser.parsePacket(packet)
        
        // Then
        if case let .initialization(size, interval) = result {
            XCTAssertEqual(size, 24)
            XCTAssertEqual(interval, 5)
        } else {
            XCTFail("Expected initialization result")
        }
    }
    
    func testParseTimestampPacket() {
        // Given
        var packet = [UInt8](repeating: 0, count: 16)
        packet[1] = 1  // Timestamp packet
        let mockDate = Date()
        mockTimestampParser.mockDate = mockDate
        
        // When
        let result = parser.parsePacket(packet)
        
        // Then
        if case let .timestamp(date) = result {
            XCTAssertEqual(date, mockDate)
        } else {
            XCTFail("Expected timestamp result")
        }
    }
    
    func testParseDataPacket() {
        // Given
        var packet = [UInt8](repeating: 0, count: 16)
        packet[1] = 2  // Data packet
        packet[2] = 72 // Heart rate value
        
        // When
        let result = parser.parsePacket(packet)
        
        // Then
        if case let .data(heartRates) = result {
            XCTAssertEqual(heartRates.first, 72)
        } else {
            XCTFail("Expected data result")
        }
    }
    
    func testParseErrorPacket() {
        // Given
        var packet = [UInt8](repeating: 0, count: 16)
        packet[1] = 255  // Error packet
        
        // When
        let result = parser.parsePacket(packet)
        
        // Then
        if case .error = result {
            // Success
        } else {
            XCTFail("Expected error result")
        }
    }
}

class MockTimestampParser: TimestampParserType {
    var mockDate: Date?
    
    func parse(_ bytes: ArraySlice<UInt8>) -> Date? {
        return mockDate
    }
}
