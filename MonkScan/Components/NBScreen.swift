import SwiftUI

struct NBScreen<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            NBColors.paper.ignoresSafeArea()
            content.padding(.horizontal, NBTheme.padding)
        }
    }
}
