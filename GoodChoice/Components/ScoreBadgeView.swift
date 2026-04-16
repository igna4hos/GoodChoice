import SwiftUI

struct ScoreBadgeView: View {
    let score: Int

    private var tint: Color {
        switch score {
        case 75...100: return AppTheme.green
        case 45..<75: return AppTheme.orange
        default: return AppTheme.red
        }
    }

    var body: some View {
        Text("\(score)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.12))
            )
    }
}
