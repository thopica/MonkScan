import SwiftUI

struct NBTopBar: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(title).font(NBType.title).foregroundStyle(NBColors.ink)
            Spacer()
            if let trailing { trailing }
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}
