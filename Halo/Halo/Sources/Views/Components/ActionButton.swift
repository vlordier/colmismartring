import SwiftUI

struct ActionButton: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .font(.system(size: ViewConstants.FontSize.body, weight: .semibold))
            .padding(ViewConstants.Spacing.medium)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(ViewConstants.CornerRadius.small)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
    }
}

struct ActionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActionButton(title: "Primary Action", color: ViewConstants.Colors.primary)
            ActionButton(title: "Success Action", color: ViewConstants.Colors.success)
            ActionButton(title: "Warning Action", color: ViewConstants.Colors.warning)
            ActionButton(title: "Error Action", color: ViewConstants.Colors.error)
        }
        .padding()
    }
}
