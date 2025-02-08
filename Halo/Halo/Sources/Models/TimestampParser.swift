import Foundation

protocol TimestampParserType {
    func parse(_ bytes: ArraySlice<UInt8>) -> Date?
}

final class TimestampParser: TimestampParserType {
    func parse(_ bytes: ArraySlice<UInt8>) -> Date? {
        guard bytes.count >= 4 else { return nil }
        
        let timestamp = UInt32(bytes[bytes.startIndex]) |
            UInt32(bytes[bytes.startIndex + 1]) << 8 |
            UInt32(bytes[bytes.startIndex + 2]) << 16 |
            UInt32(bytes[bytes.startIndex + 3]) << 24
            
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}
