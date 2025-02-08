import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(ViewConstants.CornerRadius.medium)
            .shadow(
                color: .black.opacity(0.1),
                radius: ViewConstants.Shadow.small.radius,
                x: ViewConstants.Shadow.small.x,
                y: ViewConstants.Shadow.small.y
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
