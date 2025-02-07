import CoreBluetooth

struct DiscoveredRing: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    
    init(peripheral: CBPeripheral) {
        self.id = peripheral.identifier
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Ring"
    }
}
