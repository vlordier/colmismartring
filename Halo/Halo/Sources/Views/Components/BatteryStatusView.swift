import SwiftUI

struct BatteryStatusView: View {
    let batteryInfo: BatteryInfo?
    
    var body: some View {
        if let info = batteryInfo {
            VStack(spacing: ViewConstants.Spacing.medium) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(info.batteryLevel) / 100)
                        .stroke(
                            info.batteryLevel > 20 ? Color.green : Color.red,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(info.batteryLevel)%")
                            .font(.system(size: ViewConstants.FontSize.title2, weight: .bold, design: .rounded))
                        
                        if info.charging {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()
                
                Text(info.charging ? "Charging" : "Not Charging")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(ViewConstants.Spacing.medium)
            .background(.ultraThinMaterial)
            .cornerRadius(ViewConstants.CornerRadius.medium)
            .modifier(CardStyle())
        } else {
            ContentUnavailableView(
                "Battery Status",
                systemImage: "battery.0",
                description: Text("Tap 'Get Battery Status' to check the ring's battery level")
            )
        }
    }
}

#Preview {
    BatteryStatusView(batteryInfo: BatteryInfo(batteryLevel: 85, charging: true))
}
