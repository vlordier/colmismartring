import AccessorySetupKit
import SwiftUI

struct DeviceSection: View {
    @ObservedObject var viewModel: RingViewModel

    var body: some View {
        Section {
            if viewModel.ringSessionManager.pickerDismissed,
               let currentRing = viewModel.ringSessionManager.currentRing {
                makeRingView(ring: currentRing)
            } else {
                Button {
                    viewModel.ringSessionManager.presentPicker()
                } label: {
                    Text("Add Ring")
                        .frame(maxWidth: .infinity)
                        .font(.headline.weight(.semibold))
                }
            }
        } header: {
            Text("MY DEVICE")
                .font(.system(size: ViewConstants.FontSize.title, weight: .bold))
        }
    }

    @ViewBuilder
    private func makeRingView(ring: ASAccessory) -> some View {
        HStack {
            Image("colmi")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 70)

            VStack(alignment: .leading) {
                Text(ring.displayName)
                    .font(.headline.weight(.semibold))
            }
        }
    }
}
