import SwiftUI

struct ActionButtonStyle: ViewModifier {
    let color: Color
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(ViewConstants.Spacing.medium)
            .background(isLoading ? color.opacity(0.7) : color)
            .foregroundColor(.white)
            .cornerRadius(ViewConstants.CornerRadius.small)
            .disabled(isLoading)
    }
}

extension View {
    func actionButtonStyle(color: Color, isLoading: Bool = false) -> some View {
        modifier(ActionButtonStyle(color: color, isLoading: isLoading))
    }
}

struct ActionButton: View {
    let title: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void

    init(
        title: String,
        color: Color,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                
                Text(title)
                    .frame(maxWidth: .infinity)
                    .font(.system(size: ViewConstants.FontSize.body, weight: .semibold))
            }
            .padding(ViewConstants.Spacing.medium)
            .background(isLoading ? color.opacity(0.7) : color)
            .foregroundColor(.white)
            .cornerRadius(ViewConstants.CornerRadius.small)
        }
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isLoading ? "Loading" : "")
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActionButton(title: "Primary Action", color: ViewConstants.Colors.primary) {}
            ActionButton(title: "Success Action", color: ViewConstants.Colors.success) {}
            ActionButton(title: "Warning Action", color: ViewConstants.Colors.warning) {}
            ActionButton(title: "Error Action", color: ViewConstants.Colors.error) {}
        }
        .padding()
    }
}
