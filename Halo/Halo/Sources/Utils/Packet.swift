import Foundation

/// Utilities for creating and validating data packets for ring device communication
/// 
/// Packet Structure:
/// ```
/// +------------+----------------+-----------+
/// | Command(1) | Sub-data(0-14) | Check(1) |
/// +------------+----------------+-----------+
/// ```
/// - Command: Single byte indicating packet type
/// - Sub-data: Optional payload (up to 14 bytes)
/// - Check: Checksum byte for error detection

/// Creates a properly formatted packet for communication with the ring device
///
/// Packet Format:
/// - Byte 0: Command byte (0-255)
/// - Bytes 1-14: Optional sub-data (up to 14 bytes)
/// - Byte 15: Checksum byte
///
/// The checksum is calculated as the sum of all other bytes modulo 255
///
/// - Parameters:
///   - command: The command byte to send (0-255)
///   - subData: Optional additional data bytes (max 14 bytes)
/// - Returns: A complete 16-byte packet with checksum
/// - Throws: PacketError if command or subData are invalid
func makePacket(command: UInt8, subData: [UInt8]? = nil) throws -> [UInt8] {
    // Ensure the command is between 0 and 255
    guard command <= 255 else {
        throw PacketError.invalidCommand
    }
    
    // Validate raw commands
    if command == PacketCommand.raw.rawValue {
        guard let subData = subData,
              subData.count >= 2,
              RawSubcommand(rawValue: subData[0]) != nil,
              subData[1] == 0x04 else {
            throw PacketError.invalidRawCommand
        }
    }

    // Initialize a 16-byte packet filled with zeros
    var packet = [UInt8](repeating: 0, count: 16)
    packet[0] = command

    // Validate and copy subData into the packet if provided
    if let subData {
        guard subData.count <= 14 else {
            throw PacketError.invalidSubDataLength
        }
        for (index, byte) in subData.enumerated() {
            packet[index + 1] = byte
        }
    }

    // Calculate and set the checksum (last byte of the packet)
    packet[15] = checksum(packet: packet)

    return packet
}

/// Calculates the checksum for a packet
///
/// The checksum is calculated by summing all bytes in the packet (excluding the checksum byte)
/// and taking the modulo 255 of the result. This provides a simple error detection mechanism.
///
/// - Parameter packet: The packet bytes to calculate checksum for (should be 16 bytes)
/// - Returns: The calculated checksum byte
func checksum(packet: [UInt8]) -> UInt8 {
    // Only sum the first 15 bytes (excluding checksum byte)
    let relevantBytes = packet[0..<15]
    let sum = relevantBytes.reduce(0) { result, byte in
        result + UInt(byte)
    }
    return UInt8(sum % 255)
}
