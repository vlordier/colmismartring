//
//  HaloApp.swift
//  Halo
//
//  Created by Yannis De Cleene on 20/01/2025.
//

import SwiftUI
import HealthKit

@main
struct HaloApp: App {
    @StateObject private var healthKitService = HealthKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitService)
                .task {
                    await requestHealthKitAuthorization()
                }
        }
    }

    private func requestHealthKitAuthorization() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            healthKitService.requestAuthorization { success in
                print("HealthKit auth", success != false ? "granted" : "denied")
                continuation.resume()
            }
        }
    }
}
