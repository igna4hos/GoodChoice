import SwiftUI

struct PremiumCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.surface)
                    .shadow(color: AppTheme.subtleShadow, radius: 18, x: 0, y: 12)
            )
    }
}

#Preview {
    PremiumCard {
        Text("Preview")
    }
    .padding()
    .background(AppTheme.background)
}
