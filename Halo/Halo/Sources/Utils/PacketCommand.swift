import Foundation

enum PacketCommand: UInt8, CaseIterable {
    case raw = 0xA1
    case heartRate = 0x15
    case battery = 0x03
    case blink = 0x10
    
    var requiresChecksum: Bool {
        switch self {
        case .raw: return true
        default: return false
        }
    }
    
    var maxSubDataLength: Int {
        switch self {
        case .raw: return 14
        case .heartRate: return 4
        case .battery: return 0
        case .blink: return 0
        }
    }
    
    func validateSubData(_ data: [UInt8]?) -> Bool {
        guard let data = data else {
            return maxSubDataLength == 0
        }
        return data.count <= maxSubDataLength
    }
}
