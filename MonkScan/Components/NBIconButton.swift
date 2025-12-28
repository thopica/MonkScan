import SwiftUI

struct NBIconButton: View {
    let systemName: String
    var filled: Bool = true
    var size: CGFloat = 44
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NBColors.ink)
                .frame(width: size, height: size)
                .background(filled ? NBColors.yellow : NBColors.warmCard)
                .overlay(Circle().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? "")
        .accessibilityHint(accessibilityHint ?? "")
    }
}
