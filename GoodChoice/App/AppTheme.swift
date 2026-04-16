import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let surface = Color.white
    static let green = Color(red: 0.19, green: 0.68, blue: 0.40)
    static let orange = Color(red: 0.96, green: 0.56, blue: 0.18)
    static let red = Color(red: 0.90, green: 0.29, blue: 0.26)
    static let yellow = Color(red: 0.95, green: 0.73, blue: 0.24)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.97, blue: 0.91),
            Color(red: 0.93, green: 0.98, blue: 0.95),
            Color.white
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let premiumGradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.74, blue: 0.33),
            Color(red: 0.96, green: 0.52, blue: 0.15)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleShadow = Color.black.opacity(0.08)
}
