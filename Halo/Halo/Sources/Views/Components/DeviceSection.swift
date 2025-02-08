import AccessorySetupKit
import CoreBluetooth
import SwiftUI

struct DeviceSection: View {
    @ObservedObject var viewModel: RingViewModel
    @State private var showOnboarding = false

    var body: some View {
        Section {
            if let currentRing = viewModel.ringSessionManager.currentRing {
                makeRingView(ring: currentRing)
                
                if !viewModel.ringSessionManager.peripheralConnected {
                    Button(action: { viewModel.ringSessionManager.connect() }) {
                        Label("Reconnect", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.isScanning {
                VStack(spacing: 12) {
                    ProgressView("Scanning for rings...")
                        .progressViewStyle(.circular)
                    
                    if viewModel.discoveredRings.isEmpty {
                        Text("Make sure your ring is nearby and powered on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(viewModel.discoveredRings) { ring in
                        Button(action: {
                            viewModel.connect(to: viewModel.ringSessionManager.currentRing ?? ASAccessory())
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: "ring")
                                    .foregroundColor(.accentColor)
                                Text(ring.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                        }
                    }
                    
                    Button("Cancel Scanning", role: .cancel) {
                        viewModel.stopScanning()
                    }
                    .padding(.top)
                }
            } else {
                VStack(spacing: 16) {
                    Button {
                        viewModel.startScanning()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Label("Add Ring", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button("How to Connect?") {
                        showOnboarding = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(ring.displayName)
                    .font(.headline.weight(.semibold))
                
                if viewModel.ringSessionManager.peripheralConnected {
                    Text("Connected")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("Disconnected")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(ring.displayName), \(viewModel.ringSessionManager.peripheralConnected ? "Connected" : "Disconnected")")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
