//
//  HeartRate.swift
//  Halo
//
//  Created by Yannis De Cleene on 27/01/2025.
//

import Foundation

/// Command constants for heart rate related operations
/// Each command represents a specific operation that can be performed with the ring device

/// Command to read historical heart rate data (0x15)
let CMD_READ_HEART_RATE: UInt8 = 21

/// Command mapping for different sensor operations:
/// - 21: Read heart rate history
/// - 22: Toggle heart rate detection (1=ON, 2=OFF)
/// - 43: Toggle SPO2 detection (1=ON, 2=OFF)
/// - 55: Toggle HRV detection (1=ON, 2=OFF)
/// - 53: Toggle stress detection (1=ON, 2=OFF)
/*
  Received value: 16 bytes : [3, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65]

  Received value: 16 bytes : [7, 0, 128, 36, 9, 33, 0, 0, 0, 0, 0, 0, 0, 2, 242, 201]
  Received value: 16 bytes : [7, 1, 128, 36, 9, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 214]

  Received value: 16 bytes : [7, 0, 0, 37, 1, 39, 0, 0, 44, 0, 0, 0, 0, 9, 248, 129]
  Received value: 16 bytes : [7, 1, 0, 37, 1, 39, 0, 0, 0, 0, 2, 0, 0, 0, 0, 87]
  HRL Commmand Sent
  Write to characteristic successful
  🔥
  Received value: 16 bytes : [7, 0, 128, 36, 9, 33, 0, 0, 0, 0, 0, 0, 0, 9, 248, 214]
  🔥
  Received value: 16 bytes : [7, 1, 128, 36, 9, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 214]

 Received value: 16 bytes : [10, 2, 204, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 110]
 Received value: 16 bytes : [67, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66]
 Received value: 16 bytes : [67, 255, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67]
 Received value: 16 bytes : [67, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66]
 Received value: 16 bytes : [72, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72]

  Received value: 16 bytes : [67, 240, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53]
  Received value: 16 bytes : [67, 37, 1, 39, 56, 0, 1, 255, 0, 44, 0, 36, 0, 0, 0, 24]
  Received value: 16 bytes : [67, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 66]
  Received value: 16 bytes : [72, 0, 0, 44, 0, 0, 0, 0, 9, 248, 0, 0, 36, 0, 2, 155]

  44 steps?
  2 kcal?

  Received value: 16 bytes : [72, 0, 0, 44, 0, 0, 0, 0, 9, 248, 0, 0, 36, 0, 2, 155]
  Received value: 16 bytes : [67, 240, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53]
  Received value: 16 bytes : [67, 37, 1, 39, 56, 0, 1, 255, 0, 44, 0, 36, 0, 0, 0, 24]
  Invalid heart rate log packet received.
  Received value: 16 bytes : [21, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20]
  Invalid heart rate log packet received.
  Received value: 16 bytes : [21, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20]
  Received value: 16 bytes : [55, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 54]
  Received value: 16 bytes : [55, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 54]
  Received value: 16 bytes : [57, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56]
  Received value: 16 bytes : [57, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56]
  Received value: 16 bytes : [115, 18, 0, 0, 57, 0, 12, 234, 0, 0, 47, 0, 0, 0, 0, 227]
  Received value: 16 bytes : [115, 18, 0, 0, 58, 0, 13, 36, 0, 0, 48, 0, 0, 0, 0, 32]
  Received value: 16 bytes : [115, 18, 0, 0, 59, 0, 13, 94, 0, 0, 48, 0, 0, 0, 0, 91]
  Received value: 16 bytes : [115, 18, 0, 0, 61, 0, 13, 210, 0, 0, 50, 0, 0, 0, 0, 211]
  Received value: 16 bytes : [115, 18, 0, 0, 62, 0, 14, 12, 0, 0, 51, 0, 0, 0, 0, 16]
  Received value: 16 bytes : [115, 18, 0, 0, 63, 0, 14, 70, 0, 0, 52, 0, 0, 0, 0, 76]
  Received value: 16 bytes : [115, 18, 0, 0, 63, 0, 14, 70, 0, 0, 52, 0, 0, 0, 0, 76]
  Received value: 16 bytes : [115, 18, 0, 0, 65, 0, 14, 186, 0, 0, 53, 0, 0, 0, 0, 195]
  Received value: 16 bytes : [115, 18, 0, 0, 66, 0, 14, 244, 0, 0, 54, 0, 0, 0, 0, 255]
  Received value: 16 bytes : [115, 18, 0, 0, 67, 0, 15, 46, 0, 0, 55, 0, 0, 0, 0, 60]
  Received value: 16 bytes : [115, 18, 0, 0, 68, 0, 15, 104, 0, 0, 56, 0, 0, 0, 0, 120]
  Received value: 16 bytes : [115, 18, 0, 0, 70, 0, 15, 220, 0, 0, 58, 0, 0, 0, 0, 240]
  Received value: 16 bytes : [115, 18, 0, 0, 70, 0, 15, 220, 0, 0, 58, 0, 0, 0, 0, 240]
  Received value: 16 bytes : [115, 18, 0, 0, 71, 0, 16, 22, 0, 0, 58, 0, 0, 0, 0, 44]
  Received value: 16 bytes : [115, 18, 0, 0, 73, 0, 16, 138, 0, 0, 60, 0, 0, 0, 0, 164]
  Received value: 16 bytes : [115, 18, 0, 0, 74, 0, 16, 196, 0, 0, 61, 0, 0, 0, 0, 224]
  Received value: 16 bytes : [115, 18, 0, 0, 75, 0, 16, 254, 0, 0, 62, 0, 0, 0, 0, 28]
  Received value: 16 bytes : [115, 18, 0, 0, 76, 0, 17, 56, 0, 0, 63, 0, 0, 0, 0, 89]
  Received value: 16 bytes : [115, 18, 0, 0, 76, 0, 17, 56, 0, 0, 63, 0, 0, 0, 0, 89]
  Received value: 16 bytes : [115, 18, 0, 0, 78, 0, 17, 172, 0, 0, 64, 0, 0, 0, 0, 208]
  Received value: 16 bytes : [115, 18, 0, 0, 79, 0, 17, 230, 0, 0, 65, 0, 0, 0, 0, 12]
  Received value: 16 bytes : [115, 18, 0, 0, 79, 0, 17, 230, 0, 0, 65, 0, 0, 0, 0, 12]

  21 is read HR
  Received value: 16 bytes : [22, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26] HR Detection OFF
  Received value: 16 bytes : [22, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 25] HR Detection ON

  55 is read HRV -> Yes
  Received value: 16 bytes : [56, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60] HRV Detection OFF
  Received value: 16 bytes : [56, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59] HRV Detection ON

  43 is read SPO2?
  Received value: 16 bytes : [44, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 46] SPO2 Detection OFF
  Received value: 16 bytes : [44, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47] SPO2 Detection ON

  53 is read stress?
  Received value: 16 bytes : [54, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56] Stress Detection OFF
  Received value: 16 bytes : [54, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57] Stress Detection ON
  */
// 22 did something
// 24 did something also as command
// 33 did something also as command
// 39 gave a stream on command
// 44 did something also as command
// 49 did something also as command
// 54 did something also as command
// 55 gave a stream on command
// 56 did something also as command
// 57 gave a stream on command
// 60 did something also as command
// 67 gave a stream on command
// 68 did something also as command

/// Manages command cycling for testing different sensor modes
/// This class helps in debugging and testing different sensor commands
/// by providing a way to increment through various command values
class Counter {
    /// Singleton instance for global access
    static let shared = Counter()

    /// Current command value, starting with SPO2 detection (43)
    var CMD_X: UInt8 = 43

    /// Increments the command value to test different sensor modes
    func increment() {
        CMD_X += 1
    }
}

/// Global counter instance for convenience
let counter = Counter()

// MARK: - Packet Creation Helper Functions

/// Creates a packet to request heart rate data for a specific date
///
/// This function creates a properly formatted packet to request historical heart rate data
/// from the ring device. The target date is converted to a Unix timestamp and included
/// in the packet's data section.
///
/// - Parameter target: The date for which to request heart rate data (should be midnight)
/// - Returns: A formatted packet ready to send to the device
/// - Throws: PacketError if packet creation fails
func readHeartRatePacket(for target: Date) throws -> [UInt8] {
    let timestamp = Int(target.timeIntervalSince1970)
    let data = withUnsafeBytes(of: UInt32(timestamp).littleEndian) { Array($0) }
    return try makePacket(command: CMD_READ_HEART_RATE, subData: data)
}

func readXPacket(for target: Date) throws -> [UInt8] {
    // Target datetime should be at midnight for the day of interest
    let timestamp = Int(target.timeIntervalSince1970)
    let data = withUnsafeBytes(of: UInt32(timestamp).littleEndian) { Array($0) }
    return try makePacket(command: Counter.shared.CMD_X, subData: data)
}

func addTimes(heartRates: [Int], timestamp: Date) throws -> [(Int, Date)] {
    guard heartRates.count == 288 else {
        throw HeartRateError.invalidHeartRateCount
    }
    var result: [(Int, Date)] = []
    var current = Calendar.current.startOfDay(for: timestamp)
    let interval = TimeInterval(5 * 60) // 5 minutes
    for hr in heartRates {
        result.append((hr, current))
        current.addTimeInterval(interval)
    }
    return result
}

/// Represents a complete log of heart rate measurements for a specific time period
///
/// The HeartRateLog contains an array of heart rate measurements taken at regular
/// intervals (typically every 5 minutes) throughout a day, along with metadata
/// about the measurements such as timestamp and sampling interval.
struct HeartRateLog {
    /// Array of heart rate values (typically 288 values for a full day)
    var heartRates: [Int]

    /// Raw packet data for debugging purposes
    var allPackets: [UInt8] = []

    /// Start timestamp for the heart rate measurements
    var timestamp: Date

    /// Number of hours of data contained in the log
    var size: Int

    /// Current processing index
    var index: Int

    /// Sampling interval in minutes (typically 5)
    var range: Int

    /// Returns an array of tuples containing heart rate values and their corresponding timestamps
    /// Filters out zero values which indicate invalid or missing readings
    ///
    /// - Returns: Array of (heartRate, timestamp) tuples
    /// - Throws: HeartRateError if the data format is invalid
    func heartRatesWithTimes() throws -> [(Int, Date)] {
        try addTimes(heartRates: heartRates, timestamp: timestamp)
            .filter { $0.0 != 0 }
    }
}

// NoData Class
class NoData {}

// HeartRateLogParser Class
class HeartRateLogParser {
    private var rawHeartRates: [Int] = []
    private var allPackets: [UInt8] = [] // debug purposes
    private(set) var timestamp: Date?
    private(set) var size = 0
    private(set) var index = 0
    private(set) var end = false
    private(set) var range = 5

    init() {
        reset()
    }

    func reset() {
        rawHeartRates = []
        timestamp = nil
        size = 0
        index = 0
        end = false
        range = 5
    }

    func isToday() -> Bool {
        guard let timestamp else { return false }
        return Calendar.current.isDateInToday(timestamp)
    }

    // The first byte is the heartrate command
    // The second byte is the subtype (the how manieth packet out of the total size)
    // The third until fifteenth byte are the data (13 bytes)
    // The last byte is the checksum
    func parse(packet: [UInt8]) -> Any? {
        guard packet.count >= 16 else { return nil }
        let subType = packet[1]

        let dataSize = 13

        print(packet)
        allPackets += packet

        if subType == 255 {
            print("Error: Invalid response from heart rate log request")
            reset()
            return NoData()
        }

        if isToday(), subType == 23 {
            guard let timestamp else { return nil }
            let log = HeartRateLog(
                heartRates: heartRates,
                allPackets: allPackets,
                timestamp: timestamp,
                size: size,
                index: index,
                range: range
            )
            reset()
            return log
        }

        if subType == 0 {
            end = false

            size = Int(packet[2])
            print("Measurements of the last \(size) hours.")

            range = Int(packet[3])
            print("Measured every \(range) minutes")

            rawHeartRates = Array(repeating: -1, count: size * dataSize)
            return nil
        } else if subType == 1 {
            // Safely extract timestamp using timestampToDate
            let ts = extractTimestamp(from: packet)
            timestamp = timestampToDate(timestamp: ts)

            // Safely replace subrange of rawHeartRates
            let startRange = 0 ..< 9
            let packetRange = 6 ..< 15
            if startRange.upperBound <= rawHeartRates.count, packetRange.count <= startRange.count {
                rawHeartRates.replaceSubrange(startRange, with: packet[packetRange].map { Int($0) })
            } else {
                print("Error: Subrange replacement out of bounds. RawHeartRates count: \(rawHeartRates.count), startRange: \(startRange), packetRange: \(packetRange)")
            }
            index += 9
            return nil
        } else {
            let startIndex = index
            let endIndex = index + 13
            let packetRange = 2 ..< 15
            if endIndex <= rawHeartRates.count {
                rawHeartRates.replaceSubrange(startIndex ..< endIndex, with: packetRange.map { Int(packet[$0]) })
            }
            index = endIndex
            if subType == size - 1, let timestamp {
                let log = HeartRateLog(
                    heartRates: heartRates,
                    timestamp: timestamp,
                    size: size,
                    index: index,
                    range: range
                )
                reset()
                return log
            }
            return nil
        }
    }

    var heartRates: [Int] {
        var hr = rawHeartRates
        if hr.count > 288 {
            hr = Array(hr.prefix(288))
        } else if hr.count < 288 {
            hr.append(contentsOf: Array(repeating: 0, count: 288 - hr.count))
        }

        if isToday() {
            let minutesElapsed = (Calendar.current.dateComponents([.minute], from: Calendar.current.startOfDay(for: Date()), to: Date()).minute ?? 0) / 5
            for i in minutesElapsed ..< hr.count {
                hr[i] = 0
            }
        }
        return hr
    }
}

// Custom Errors
enum HeartRateError: Error {
    case invalidHeartRateCount
}

func extractTimestamp(from packet: [UInt8]) -> UInt32 {
    let timestamp = UInt32(packet[2]) |
        UInt32(packet[3]) << 8 |
        UInt32(packet[4]) << 16 |
        UInt32(packet[5]) << 24
    return timestamp
}

// Adjust this function to handle UTC time
func timestampToDate(timestamp: UInt32) -> Date {
    Date(timeIntervalSince1970: TimeInterval(timestamp))
}

extension Date {
    func convertToTimeZone(initTimeZone: TimeZone, timeZone: TimeZone) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - initTimeZone.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}
