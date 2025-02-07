//
//  ContentView.swift
//  Halo
//
//  Created by Yannis De Cleene on 20/01/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RingViewModel()

    var body: some View {
        List {
            DeviceSection(viewModel: viewModel)

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

            Section("Battery Status") {
                Button(action: { viewModel.getBatteryStatus() }) {
                    ActionButton(title: "Get Battery Status", color: .blue)
                }

                if let info = viewModel.batteryInfo {
                    Text("Battery Level: \(info.batteryLevel)%")
                    Text("Charging: \(info.charging ? "Yes" : "No")")
                }
            }

            Section("Heart Rate Log") {
                Button(action: { viewModel.getHeartRateLog() }) {
                    ActionButton(title: "Get Heart Rate Log", color: .green)
                }

                HeartRateGraphView(data: viewModel.heartRateData)
            }

            StreamingControls(viewModel: viewModel, type: .heartRate)
            StreamingControls(viewModel: viewModel, type: .spo2)
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    ContentView()
}
