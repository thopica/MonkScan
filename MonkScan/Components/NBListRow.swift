import SwiftUI

struct NBListRow: View {
    let title: String
    let subtitle: String?
    let leadingIcon: String
    let trailing: AnyView?

    init(title: String, subtitle: String? = nil, leadingIcon: String = "doc.text", trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(NBColors.warmCard)
                    .overlay(Circle().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                Image(systemName: leadingIcon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(NBColors.ink)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(NBType.body).foregroundStyle(NBColors.ink)
                if let subtitle {
                    Text(subtitle).font(NBType.caption).foregroundStyle(NBColors.mutedInk).lineLimit(1)
                }
            }

            Spacer()
            if let trailing { trailing }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(NBColors.warmCard)
        .overlay(RoundedRectangle(cornerRadius: NBTheme.corner)
            .stroke(NBColors.ink, lineWidth: NBTheme.stroke))
        .cornerRadius(NBTheme.corner)
    }
}
