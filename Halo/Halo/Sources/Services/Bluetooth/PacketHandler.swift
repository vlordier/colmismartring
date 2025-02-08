import Foundation

protocol PacketHandler {
    func handlePacket(_ packet: [UInt8]) -> Result<Void, BluetoothError>
    func validatePacket(_ packet: [UInt8]) -> Bool
}

final class DefaultPacketHandler: PacketHandler {
    /// Processes and validates an incoming data packet from the ring device
    /// - Parameter packet: Raw byte array containing the packet data
    /// - Returns: Success if packet is valid and processed, or error if validation fails
    func handlePacket(_ packet: [UInt8]) -> Result<Void, BluetoothError> {
        // Validate packet format and checksum
        guard validatePacket(packet) else {
            Logger.bluetoothError("Invalid packet format or checksum")
            return .failure(PacketError.invalidPacketFormat)
        }
        
        // Extract command type from first byte
        let commandByte = packet[0]
        
        // Handle different packet types based on command byte
        switch commandByte {
        case PacketCommand.battery.rawValue:
            Logger.bluetoothInfo("Processing battery status packet")
            return handleBatteryPacket(packet)
            
        case PacketCommand.heartRate.rawValue:
            Logger.bluetoothInfo("Processing heart rate packet")
            return handleHeartRatePacket(packet)
            
        case PacketCommand.raw.rawValue:
            Logger.bluetoothInfo("Processing raw sensor packet")
            return handleRawPacket(packet)
            
        default:
            Logger.bluetoothInfo("Unknown but valid packet type: \(commandByte)")
            return .success(()) // Unknown packet type but valid format
        }
    }
    
    func validatePacket(_ packet: [UInt8]) -> Bool {
        guard packet.count == 16 else { return false }
        
        // Verify checksum for commands that require it
        if let command = PacketCommand(rawValue: packet[0]),
           command.requiresChecksum {
            let calculatedChecksum = checksum(packet: packet)
            return packet[15] == calculatedChecksum
        }
        
        return true
    }
    
    private func handleBatteryPacket(_ packet: [UInt8]) -> Result<Void, BluetoothError> {
        // Battery packet validation logic
        guard packet[0] == PacketCommand.battery.rawValue else {
            return .failure(.invalidPacketFormat)
        }
        return .success(())
    }
    
    private func handleHeartRatePacket(_ packet: [UInt8]) -> Result<Void, BluetoothError> {
        // Heart rate packet validation logic
        guard packet[0] == PacketCommand.heartRate.rawValue else {
            return .failure(.invalidPacketFormat)
        }
        return .success(())
    }
    
    private func handleRawPacket(_ packet: [UInt8]) -> Result<Void, BluetoothError> {
        // Raw data packet validation logic
        guard packet[0] == PacketCommand.raw.rawValue else {
            return .failure(.invalidPacketFormat)
        }
        return .success(())
    }
}
