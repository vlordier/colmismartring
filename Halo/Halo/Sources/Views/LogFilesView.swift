import SwiftUI

struct LogFilesView: View {
    let loggingService: LoggingService
    @State private var logFiles: [URL] = []
    
    var body: some View {
        List(logFiles, id: \.absoluteString) { file in
            VStack(alignment: .leading) {
                Text(file.lastPathComponent)
                    .font(.headline)
                
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let size = attributes[.size] as? Int64,
                   let date = attributes[.creationDate] as? Date {
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                        .font(.subheadline)
                    Text("Created: \(date.formatted())")
                        .font(.subheadline)
                }
            }
            .contextMenu {
                Button(action: {
                    shareFile(file)
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Sensor Logs")
        .onAppear {
            logFiles = loggingService.getLogFiles()
        }
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}
