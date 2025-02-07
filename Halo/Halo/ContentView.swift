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
            
            CommandsSection(viewModel: viewModel)
            
            Section("Battery Status") {
                Button(action: { viewModel.getBatteryStatus() }) {
                    ActionButton(title: "Get Battery Status", color: .blue)
                }
                
                BatteryStatusView(batteryInfo: viewModel.batteryInfo)
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
