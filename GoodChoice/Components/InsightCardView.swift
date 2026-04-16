import SwiftUI

struct InsightCardView: View {
    let insight: AnalyticsInsight
    let locked: Bool

    private var tint: Color {
        switch insight.tint {
        case .green: return AppTheme.green
        case .orange: return AppTheme.orange
        case .red: return AppTheme.red
        }
    }

    var body: some View {
        PremiumCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: locked ? "lock.fill" : insight.icon)
                        .foregroundStyle(tint)
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()
                }

                Text(insight.title)
                    .font(.headline)
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(locked ? 0.55 : 1.0)
        }
    }
}
