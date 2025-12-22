import SwiftUI

struct PagesView: View {
    @ObservedObject var sessionStore: ScanSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showExport = false
    
    private var pages: [ScanPage] {
        sessionStore.currentSession?.pages ?? []
    }
    
    var body: some View {
        ZStack {
            NBColors.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(NBType.body)
                        .foregroundStyle(NBColors.ink)
                    }
                    
                    Spacer()
                    
                    Text("Pages")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.ink)
                    
                    Spacer()
                    
                    Button {
                        showExport = true
                    } label: {
                        Text("Export")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(NBColors.yellow)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                    }
                    .disabled(pages.isEmpty)
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                
                // Page count
                HStack {
                    Text("\(pages.count) pages")
                        .font(NBType.body)
                        .foregroundStyle(NBColors.mutedInk)
                    Spacer()
                    if !pages.isEmpty {
                        Text("Drag to reorder")
                            .font(NBType.caption)
                            .foregroundStyle(NBColors.mutedInk)
                    }
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.bottom, 12)
                
                // Pages grid
                if pages.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundStyle(NBColors.mutedInk)
                        Text("No pages yet")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.mutedInk)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                        ], spacing: 16) {
                            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                                PageThumbnail(page: page, index: index, sessionStore: sessionStore)
                            }
                        }
                        .padding(.horizontal, NBTheme.padding)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showExport) {
            ExportView()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Page Thumbnail
struct PageThumbnail: View {
    let page: ScanPage
    let index: Int
    @ObservedObject var sessionStore: ScanSessionStore
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: NBTheme.corner)
                    .fill(NBColors.warmCard)
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay(
                        Group {
                            if let image = page.uiImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 32))
                                    .foregroundStyle(NBColors.mutedInk)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                    .overlay(
                        RoundedRectangle(cornerRadius: NBTheme.corner)
                            .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                    )
                
                // Action buttons
                HStack(spacing: 8) {
                    // Rotate button
                    Button {
                        sessionStore.rotatePage(at: index)
                    } label: {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(NBColors.ink)
                            .frame(width: 28, height: 28)
                            .background(NBColors.yellow)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(NBColors.ink, lineWidth: 1))
                    }
                    
                    // Delete button
                    Button {
                        sessionStore.removePage(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(NBColors.danger)
                            .background(Circle().fill(NBColors.paper))
                    }
                }
                .offset(x: 6, y: -6)
            }
            
            Text("Page \(index + 1)")
                .font(NBType.caption)
                .foregroundStyle(NBColors.ink)
        }
    }
}

#Preview {
    NavigationStack {
        let store = ScanSessionStore()
        let _ = {
            store.startNewSession()
            if let image = UIImage(systemName: "doc.text") {
                store.addPage(image)
            }
        }()
        return PagesView(sessionStore: store)
    }
}

