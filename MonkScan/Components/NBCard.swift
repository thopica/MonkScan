import SwiftUI

struct NBCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(14)
            .background(NBColors.warmCard)
            .overlay(RoundedRectangle(cornerRadius: NBTheme.corner)
                .stroke(NBColors.ink, lineWidth: NBTheme.stroke))
            .cornerRadius(NBTheme.corner)
            .shadow(color: NBColors.ink.opacity(0.12), radius: 0, x: 2, y: 2)
    }
}
