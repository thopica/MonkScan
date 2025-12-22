import SwiftUI

struct NBTextField: View {
    let placeholder: String
    var systemIcon: String? = "magnifyingglass"
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            if let systemIcon {
                Image(systemName: systemIcon).foregroundStyle(NBColors.mutedInk)
            }
            TextField(placeholder, text: $text)
                .font(NBType.regular)
                .foregroundStyle(NBColors.ink)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(NBColors.warmCard)
        .overlay(RoundedRectangle(cornerRadius: NBTheme.corner)
            .stroke(NBColors.ink, lineWidth: NBTheme.stroke))
        .cornerRadius(NBTheme.corner)
    }
}
