import XCTest
@testable import Halo

final class TimestampParserTests: XCTestCase {
    var parser: TimestampParser!
    
    override func setUp() {
        super.setUp()
        parser = TimestampParser()
    }
    
    func testParseValidTimestamp() {
        // Given
        let timestamp: UInt32 = 1706400000 // Some fixed timestamp
        let bytes = withUnsafeBytes(of: timestamp.littleEndian) { Array($0) }
        
        // When
        let result = parser.parse(bytes[...])
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.timeIntervalSince1970, Double(timestamp))
    }
    
    func testParseInvalidTimestamp() {
        // Given
        let bytes = ArraySlice<UInt8>([0, 1, 2]) // Too short
        
        // When
        let result = parser.parse(bytes)
        
        // Then
        XCTAssertNil(result)
    }
}
