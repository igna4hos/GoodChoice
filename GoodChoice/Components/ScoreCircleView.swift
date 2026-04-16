import SwiftUI

struct ScoreCircleView: View {
    let score: Int
    var size: CGFloat = 132
    var lineWidth: CGFloat = 14

    private var progress: Double {
        Double(score) / 100.0
    }

    private var tint: Color {
        switch score {
        case 75...100: return AppTheme.green
        case 45..<75: return AppTheme.orange
        default: return AppTheme.red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.8), tint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("score.outOf")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ScoreCircleView(score: 84)
        .padding()
}
