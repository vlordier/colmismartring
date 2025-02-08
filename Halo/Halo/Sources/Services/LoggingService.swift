import Foundation

final class LoggingService {
    enum LoggingError: LocalizedError {
        case fileCreationFailed
        case writeError
        case invalidPath
        
        var errorDescription: String? {
            switch self {
            case .fileCreationFailed: return "Failed to create log file"
            case .writeError: return "Failed to write to log file"
            case .invalidPath: return "Invalid log file path"
            }
        }
    }
    
    private let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var currentLogFile: URL? {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dateString = dateFormatter.string(from: Date())
        return documentsPath.appendingPathComponent("sensor_log_\(dateString).csv")
    }
    
    func logSensorData(_ data: SensorData) {
        guard let logFile = currentLogFile else {
            Logger.deviceError("Failed to get current log file path")
            return
        }

        do {
            let csvLine = [
                "\(data.timestamp.timeIntervalSince1970)",
                "\(data.heartRate ?? -1)",
                "\(data.spo2 ?? -1)",
                "\(data.accelerometer?.x ?? 0)",
                "\(data.accelerometer?.y ?? 0)",
                "\(data.accelerometer?.z ?? 0)",
                "\(data.ppg ?? -1)",
                "\(data.batteryLevel ?? -1)"
            ].joined(separator: ",")
            
            if !fileManager.fileExists(atPath: logFile.path) {
                let header = "timestamp,heartRate,spo2,accX,accY,accZ,ppg,batteryLevel\n"
                try header.write(to: logFile, atomically: true, encoding: .utf8)
            }
            
            if let handle = try? FileHandle(forWritingTo: logFile) {
                defer {
                    try? handle.close()
                }
                handle.seekToEndOfFile()
                handle.write((csvLine + "\n").data(using: .utf8)!)
            }
        } catch {
            Logger.deviceError("Failed to write sensor data: \(error)")
        }
    }
    
    func getLogFiles() -> [URL] {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: documentsPath,
                includingPropertiesForKeys: nil
            )
            return files.filter { $0.lastPathComponent.starts(with: "sensor_log_") }
        } catch {
            print("Error getting log files: \(error)")
            return []
        }
    }
}
