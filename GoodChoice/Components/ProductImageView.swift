import SwiftUI

struct ProductImageView: View {
    let imageName: String
    var width: CGFloat = 72
    var height: CGFloat = 72
    var cornerRadius: CGFloat = 18

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: AppTheme.subtleShadow, radius: 10, x: 0, y: 6)
    }
}
