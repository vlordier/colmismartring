import AccessorySetupKit
import CoreBluetooth
import SwiftUI

struct DeviceSection: View {
    @ObservedObject var viewModel: RingViewModel

    var body: some View {
        Section {
            if let currentRing = viewModel.ringSessionManager.currentRing {
                makeRingView(ring: currentRing)
            } else if viewModel.isScanning {
                VStack {
                    ProgressView("Scanning for rings...")
                    
                    ForEach(viewModel.discoveredRings) { ring in
                        Button(action: {
                            viewModel.connect(to: viewModel.ringSessionManager.currentRing ?? ASAccessory())
                        }) {
                            HStack {
                                Text(ring.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    
                    Button("Cancel") {
                        viewModel.stopScanning()
                    }
                }
            } else {
                Button {
                    viewModel.startScanning()
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
