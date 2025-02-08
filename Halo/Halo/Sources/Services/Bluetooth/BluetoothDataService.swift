import CoreBluetooth

/// Service for handling Bluetooth data operations
protocol BluetoothDataService: AnyObject {
    /// Sends a data packet to the connected device
    func sendPacket(_ packet: [UInt8]) async throws
    
    /// Starts a raw data stream of the specified type
    func startRawStream(type: RawStreamType)
    
    /// Stops the current raw data stream
    func stopRawStream()
}

/// Default implementation of BluetoothDataService
final class DefaultBluetoothDataService: BluetoothDataService {
    private let connectionManager: BluetoothConnectionManager
    private let packetHandler: PacketHandler
    
    init(connectionManager: BluetoothConnectionManager,
         packetHandler: PacketHandler = DefaultPacketHandler()) {
        self.connectionManager = connectionManager
        self.packetHandler = packetHandler
    }
    
    func sendPacket(_ packet: [UInt8]) async throws {
        try await connectionManager.sendPacket(packet)
    }
    
    func startRawStream(type: RawStreamType) {
        Task {
            do {
                let subcommand = RawSubcommand.from(type)
                let packet = try makePacket(
                    command: PacketCommand.raw.rawValue,
                    subData: [subcommand.rawValue, 0x04]
                )
                try await sendPacket(packet)
            } catch {
                Logger.bluetoothError("Failed to start raw stream: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRawStream() {
        Task {
            do {
                let packet = try makePacket(
                    command: PacketCommand.raw.rawValue,
                    subData: [0x02]
                )
                try await sendPacket(packet)
            } catch {
                Logger.bluetoothError("Failed to stop raw stream: \(error.localizedDescription)")
            }
        }
    }
}
