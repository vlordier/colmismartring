//
//  HaloApp.swift
//  Halo
//
//  Created by Yannis De Cleene on 20/01/2025.
//

import SwiftUI

@main
struct HaloApp: App {
    @State private var healthKitService = HealthKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKitService)
                .task {
                    await requestHealthKitAuthorization()
                }
        }
    }

    private func requestHealthKitAuthorization() async {
        await withCheckedContinuation { continuation in
            healthKitService.requestAuthorization { success in
                print("HealthKit auth \(success ? "granted" : "denied")")
                continuation.resume()
            }
        }
    }
}
