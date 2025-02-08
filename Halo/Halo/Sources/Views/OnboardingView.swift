import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image("colmi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200)
                        .padding()
                    
                    VStack(spacing: 20) {
                        OnboardingStep(
                            number: 1,
                            title: "Power On",
                            description: "Press and hold the ring's button until you see the LED light up",
                            icon: "power"
                        )
                        
                        OnboardingStep(
                            number: 2,
                            title: "Enable Bluetooth",
                            description: "Make sure your iPhone's Bluetooth is turned on",
                            icon: "bluetooth"
                        )
                        
                        OnboardingStep(
                            number: 3,
                            title: "Connect",
                            description: "Tap 'Add Ring' and select your device when it appears",
                            icon: "link"
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Connection Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct OnboardingStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 30, height: 30)
                
                Text("\(number)")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                    Text(title)
                }
                .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
}
