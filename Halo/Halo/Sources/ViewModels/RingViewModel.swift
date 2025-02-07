import AccessorySetupKit
import SwiftUI

final class RingViewModel: ObservableObject {
    @Published private(set) var ringSessionManager: RingSessionManager
    @Published var batteryInfo: BatteryInfo?
    @Published var heartRateData: [HeartRateDataPoint] = []

    init(ringSessionManager: RingSessionManager = RingSessionManager()) {
        self.ringSessionManager = ringSessionManager
    }

    func getBatteryStatus() {
        ringSessionManager.getBatteryStatus { [weak self] info in
            self?.batteryInfo = info
        }
    }

    func getHeartRateLog() {
        ringSessionManager.getHeartRateLog { [weak self] hrl in
            do {
                let heartRatesWithTimes = try hrl.heartRatesWithTimes()
                self?.heartRateData = heartRatesWithTimes.map {
                    HeartRateDataPoint(heartRate: $0.0, time: $0.1)
                }
            } catch {
                print("Error loading data: \(error)")
            }
        }
    }
}
