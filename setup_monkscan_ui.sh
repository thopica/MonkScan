#!/usr/bin/env bash
set -e

PROJECT_ROOT="$HOME/iOSApps/MonkScan"
SOURCE_DIR="$PROJECT_ROOT/MonkScan"

echo "Project root: $PROJECT_ROOT"
echo "Source dir:   $SOURCE_DIR"

test -d "$PROJECT_ROOT" || { echo "❌ Not found: $PROJECT_ROOT"; exit 1; }
test -d "$SOURCE_DIR" || { echo "❌ Not found: $SOURCE_DIR"; exit 1; }

mkdir -p "$PROJECT_ROOT/Docs"
mkdir -p "$SOURCE_DIR/Theme" "$SOURCE_DIR/Components" "$SOURCE_DIR/Features/Library"

cat > "$PROJECT_ROOT/Docs/STYLEGUIDE.md" <<'EOF'
# MonkScan Style Guide (Neo-Brutal iOS)

- Thick outlines (2–3pt)
- Paper background
- One loud yellow
- Minimal choices, big touch targets

Colors:
- Paper: #F3EBDD
- Ink: #121212
- Muted: #4B4B4B
- Warm Card: #FFF9EF
- Yellow: #F2D23B
- Danger: #E74C3C
EOF

cat > "$SOURCE_DIR/Theme/NBColors.swift" <<'EOF'
import SwiftUI

enum NBColors {
    static let paper = Color(hex: "F3EBDD")
    static let ink = Color(hex: "121212")
    static let mutedInk = Color(hex: "4B4B4B")
    static let warmCard = Color(hex: "FFF9EF")
    static let yellow = Color(hex: "F2D23B")
    static let danger = Color(hex: "E74C3C")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
EOF

cat > "$SOURCE_DIR/Theme/NBTypography.swift" <<'EOF'
import SwiftUI

enum NBType {
    static let title = Font.system(size: 32, weight: .heavy, design: .rounded)
    static let header = Font.system(size: 20, weight: .bold, design: .rounded)
    static let body = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let regular = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
}
EOF

cat > "$SOURCE_DIR/Theme/NBTheme.swift" <<'EOF'
import SwiftUI

enum NBTheme {
    static let corner: CGFloat = 16
    static let stroke: CGFloat = 2
    static let padding: CGFloat = 16
}
EOF

cat > "$SOURCE_DIR/Components/NBScreen.swift" <<'EOF'
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
EOF

cat > "$SOURCE_DIR/Components/NBTopBar.swift" <<'EOF'
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
EOF

cat > "$SOURCE_DIR/Components/NBCard.swift" <<'EOF'
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
EOF

cat > "$SOURCE_DIR/Components/NBIconButton.swift" <<'EOF'
import SwiftUI

struct NBIconButton: View {
    let systemName: String
    var filled: Bool = true
    var size: CGFloat = 44
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
    }
}
EOF

cat > "$SOURCE_DIR/Components/NBTextField.swift" <<'EOF'
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
EOF

cat > "$SOURCE_DIR/Components/NBChip.swift" <<'EOF'
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
EOF

cat > "$SOURCE_DIR/Components/NBListRow.swift" <<'EOF'
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
EOF

cat > "$SOURCE_DIR/Features/Library/LibraryModels.swift" <<'EOF'
import Foundation

struct ScanFolder: Identifiable {
    let id = UUID()
    var name: String
    var count: Int
}

struct ScanDoc: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var stars: Int
}
EOF

cat > "$SOURCE_DIR/Features/Library/LibraryView.swift" <<'EOF'
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
            .overlay(alignment: .bottomTrailing) {
                NBIconButton(systemName: "plus", filled: true, size: 64) { }
                    .padding(.bottom, 18)
                    .padding(.trailing, 4)
            }
        }
    }
}

#Preview { LibraryView() }
EOF

echo "✅ MonkScan UI kit files created."
