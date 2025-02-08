import SwiftUI

struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                        .onAppear {
                            if !isRefreshing {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                action()
                            }
                        }
                    Spacer()
                }
            }
        }
        .frame(height: 50)
    }
}
