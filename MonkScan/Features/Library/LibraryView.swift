import SwiftUI

struct LibraryView: View {
    @State private var query = ""

    private let folders: [ScanFolder] = [
        .init(name: "Receipts", count: 24),
        .init(name: "Contracts", count: 12),
    ]

    private let recents: [ScanDoc] = [
        .init(title: "Utilities April 2024", subtitle: "Auto • 3 pages", stars: 15),
        .init(title: "Training Notes", subtitle: "B&W • 2 pages", stars: 35),
        .init(title: "Invoice 00123.pdf", subtitle: "Color • 1 page", stars: 10),
        .init(title: "Meeting Handout", subtitle: "Auto • 4 pages", stars: 20),
    ]

    var body: some View {
        NBScreen {
            VStack(spacing: 14) {
                NBTopBar(
                    title: "MonkScan",
                    trailing: AnyView(NBIconButton(systemName: "bell", filled: false) {})
                )

                NBTextField(placeholder: "Search…", text: $query)

                NBCard {
                    HStack {
                        Text("Folders").font(NBType.header).foregroundStyle(NBColors.ink)
                        Spacer()
                        NBIconButton(systemName: "plus", filled: true, size: 40) {}
                    }

                    VStack(spacing: 10) {
                        ForEach(folders) { f in
                            NBListRow(
                                title: f.name,
                                subtitle: "\(f.count) scans",
                                leadingIcon: "folder",
                                trailing: AnyView(NBChip(text: "★", filled: false))
                            )
                        }
                    }
                    .padding(.top, 10)
                }

                Text("Recent Scans")
                    .font(NBType.header)
                    .foregroundStyle(NBColors.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(recents.filter {
                            query.isEmpty ? true : $0.title.lowercased().contains(query.lowercased())
                        }) { doc in
                            NBListRow(
                                title: doc.title,
                                subtitle: doc.subtitle,
                                leadingIcon: "doc.text",
                                trailing: AnyView(
                                    HStack(spacing: 8) {
                                        NBChip(text: "\(doc.stars) ★", filled: true)
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(NBColors.ink)
                                    }
                                )
                            )
                        }
                    }
                    .padding(.bottom, 90)
                }

                Spacer()
            }
        }
    }
}

#Preview { LibraryView() }
