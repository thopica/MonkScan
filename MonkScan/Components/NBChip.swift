import SwiftUI

struct NBChip: View {
    let text: String
    var filled: Bool = true

    var body: some View {
        Text(text)
            .font(NBType.caption)
            .foregroundStyle(NBColors.ink)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(filled ? NBColors.yellow : NBColors.warmCard)
            .overlay(RoundedRectangle(cornerRadius: 999)
                .stroke(NBColors.ink, lineWidth: NBTheme.stroke))
            .cornerRadius(999)
    }
}
