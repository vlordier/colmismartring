import Foundation

private func bcdToDecimal(_ bcd: UInt8) -> Int {
    ((Int(bcd) >> 4) * 10) + (Int(bcd) & 0x0F)
}

class SportDetailParser {
    enum ParseResult {
        case complete([SportDetail])
        case partial
        case noData
    }

    private var newCalorieProtocol = false
    private var currentDetails: [SportDetail] = []
    private var expectedCount = 0
    private var currentIndex = 0

    func reset() {
        newCalorieProtocol = false
        currentDetails = []
        expectedCount = 0
        currentIndex = 0
    }

    func parse(packet: [UInt8]) -> ParseResult {
        guard packet.count == 16,
              packet.indices.contains(12),
              packet.indices.contains(6),
              packet[6] > 0,
              packet[6] <= 255 else {
            return .noData
        }
        
        guard Int(packet[5]) == currentIndex else {
            reset()
            return .noData
        }

        // Handle initial packet
        if currentIndex == 0 {
            if packet[1] == 0xFF {
                reset()
                return .noData
            }

            if packet[1] == 0xF0 {
                newCalorieProtocol = packet[3] == 0x01
                currentIndex += 1
                return .partial
            }
        }

        // Parse regular data packet
        let year = bcdToDecimal(packet[1]) + 2000
        let month = bcdToDecimal(packet[2])
        let day = bcdToDecimal(packet[3])
        let timeIndex = Int(packet[4])

        let calories = {
            let base = Int(packet[7]) + (Int(packet[8]) << 8)
            return newCalorieProtocol ? base * 10 : base
        }()

        let steps = Int(packet[9]) + (Int(packet[10]) << 8)
        let distance = Int(packet[11]) + (Int(packet[12]) << 8)

        let detail = SportDetail(
            year: year,
            month: month,
            day: day,
            timeIndex: timeIndex,
            calories: calories,
            steps: steps,
            distance: distance
        )

        currentDetails.append(detail)

        // Check if final packet
        if packet[5] == packet[6] - 1 {
            let result = currentDetails
            reset()
            return .complete(result)
        }

        currentIndex += 1
        return .partial
    }
}
