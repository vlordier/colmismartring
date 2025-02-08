import SwiftUI

/// Constants used for consistent UI styling throughout the app
enum ViewConstants {
    /// Spacing values for consistent layout margins and padding
    enum Spacing {
        /// Used for tight spacing between related elements (8pt)
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
    }

    /// Corner radius values for consistent rounded corners
    enum CornerRadius {
        /// Subtle rounding for small elements (8pt)
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    /// Font sizes for consistent typography
    enum FontSize {
        /// Standard body text size (16pt)
        static let body: CGFloat = 16
        static let title: CGFloat = 20
        static let headline: CGFloat = 18
        static let subheadline: CGFloat = 14
        static let caption: CGFloat = 12
        static let title2: CGFloat = 24
    }

    /// Color palette for consistent app theming
    enum Colors {
        /// Main brand color
        static let primary = Color.blue
        static let secondary = Color.gray.opacity(0.1)
        static let background = Color.black.opacity(0.05)
        static let cardBackground = Color.white.opacity(0.1)
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let text = Color.primary
        static let textSecondary = Color.secondary
    }
    
    /// Shadow configuration for depth effects
    struct ShadowConfig {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
    
    /// Shadow styles for depth effects
    enum Shadow {
        /// Subtle shadow for slight elevation
        static let small = ShadowConfig(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let medium = ShadowConfig(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = ShadowConfig(
            color: Color.black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
    }
    
    /// Animation presets for consistent motion
    enum Animation {
        /// Standard animation duration (0.3s)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
}
