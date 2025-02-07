import SwiftUI

struct CommandsSection: View {
    let viewModel: RingViewModel
    
    var body: some View {
        Section("Commands") {
            Button(action: {
                print("Last CMD_X: \(Counter.shared.CMD_X)")
                Counter.shared.increment()
            }) {
                ActionButton(title: "Increment", color: .blue)
            }

            Button(action: {
                viewModel.ringSessionManager.sendBlinkTwiceCommand()
            }) {
                ActionButton(title: "Send Blink Twice Command", color: .blue)
            }

            Button(action: {
                viewModel.ringSessionManager.sendXCommand()
            }) {
                ActionButton(title: "Send X Command", color: .blue)
            }
        }
    }
}
