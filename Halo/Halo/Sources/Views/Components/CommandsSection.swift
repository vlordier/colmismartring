import SwiftUI

/// Section containing command buttons for ring device control
struct CommandsSection: View {
    let viewModel: RingViewModel
    
    var body: some View {
        Section("Commands") {
            // Debug counter increment button
            Button {
                print("Last CMD_X: \(Counter.shared.CMD_X)")
                Counter.shared.increment()
            } label: {
                Text("Increment")
                    .frame(maxWidth: .infinity)
                    .padding(ViewConstants.Spacing.medium)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(ViewConstants.CornerRadius.small)
            }

            // Trigger LED blink pattern on ring
            Button {
                viewModel.sendBlinkTwiceCommand()
            } label: {
                Text("Send Blink Twice Command")
                    .frame(maxWidth: .infinity)
                    .padding(ViewConstants.Spacing.medium)
                    .background(ViewConstants.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(ViewConstants.CornerRadius.small)
            }

            // Send custom X command to ring
            Button {
                viewModel.sendXCommand()
            } label: {
                Text("Send X Command")
                    .frame(maxWidth: .infinity)
                    .padding(ViewConstants.Spacing.medium)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(ViewConstants.CornerRadius.small)
            }
        }
    }
}
