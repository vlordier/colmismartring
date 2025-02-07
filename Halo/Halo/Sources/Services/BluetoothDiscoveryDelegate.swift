import CoreBluetooth

/// Protocol for receiving Bluetooth device discovery events
protocol BluetoothDiscoveryDelegate: AnyObject {
    /// Called when a potential ring device is discovered
    /// - Parameters:
    ///   - service: The BluetoothService that discovered the device
    ///   - peripheral: The discovered peripheral device
    func bluetoothService(_ service: BluetoothService, didDiscover peripheral: CBPeripheral)
}

/// Default implementation for RingViewModel
extension RingViewModel: BluetoothDiscoveryDelegate {
    func bluetoothService(_ service: BluetoothService, didDiscover peripheral: CBPeripheral) {
        // Only add new devices
        if !discoveredRings.contains(where: { $0.id == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.discoveredRings.append(DiscoveredRing(peripheral: peripheral))
            }
        }
    }
}
