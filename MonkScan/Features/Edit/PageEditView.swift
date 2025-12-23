import SwiftUI

struct PageEditView: View {
    let page: ScanPage
    let pageIndex: Int
    @ObservedObject var sessionStore: ScanSessionStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Dark background for image viewing
            Color.black.ignoresSafeArea()
            
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
                        .foregroundStyle(NBColors.paper)
                    }
                    
                    Spacer()
                    
                    Text("Page \(pageIndex + 1)")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.paper)
                    
                    Spacer()
                    
                    // Delete button
                    Button {
                        sessionStore.removePage(at: pageIndex)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(NBColors.danger)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
                
                // Full image view
                if let image = page.uiImage {
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundStyle(NBColors.mutedInk)
                        Text("No image")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.mutedInk)
                    }
                    Spacer()
                }
                
                // Bottom toolbar - placeholder for future editing controls
                HStack(spacing: 32) {
                    // Placeholder edit buttons (will be functional later)
                    EditToolButton(icon: "rotate.right", label: "Rotate")
                    EditToolButton(icon: "sun.max", label: "Brightness")
                    EditToolButton(icon: "slider.horizontal.3", label: "Adjust")
                    EditToolButton(icon: "crop", label: "Crop")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, NBTheme.padding)
                .background(Color.black.opacity(0.8))
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Edit Tool Button
struct EditToolButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(NBColors.paper.opacity(0.5))
            Text(label)
                .font(NBType.caption)
                .foregroundStyle(NBColors.paper.opacity(0.5))
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    let store = ScanSessionStore()
    let _ = {
        store.startNewSession()
        if let image = UIImage(systemName: "doc.text.fill") {
            store.addPage(image)
        }
    }()
    
    if let page = store.currentSession?.pages.first {
        return PageEditView(page: page, pageIndex: 0, sessionStore: store)
    } else {
        return Text("No page")
    }
}

