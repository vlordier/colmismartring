import SwiftUI

struct BatteryStatusView: View {
    let batteryInfo: BatteryInfo?
    
    var body: some View {
        if let info = batteryInfo {
            VStack(alignment: .leading, spacing: ViewConstants.Spacing.small) {
                HStack {
                    Image(systemName: info.charging ? "battery.100.bolt" : "battery.100")
                    Text("Battery Level: \(info.batteryLevel)%")
                }
                
                HStack {
                    Image(systemName: info.charging ? "bolt.fill" : "bolt.slash")
                    Text("Charging: \(info.charging ? "Yes" : "No")")
                }
            }
        }
    }
}

#Preview {
    BatteryStatusView(batteryInfo: BatteryInfo(batteryLevel: 85, charging: true))
}
