import SwiftUI
import UniformTypeIdentifiers

struct PagesView: View {
    @ObservedObject var sessionStore: ScanSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showSaveDocument = false
    @State private var showShareSheet = false
    @State private var shareDocumentName = ""
    @State private var shareFormat: ExportShareFormat = .pdf
    @State private var draggingPage: ScanPage?
    @State private var targetedPageId: UUID?
    @State private var selectedPageIndex: Int?
    
    @State private var showExportErrorAlert = false
    @State private var exportErrorMessage = ""
    
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
                    
                    HStack(spacing: 12) {
                        // Share button (secondary)
                        Button {
                            shareDocumentName = generateDefaultTitle()
                            shareFormat = .pdf
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(NBColors.ink)
                                .frame(width: 44, height: 44)
                                .background(NBColors.warmCard)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                        }
                        .disabled(pages.isEmpty)
                        .accessibilityLabel("Share")
                        .accessibilityHint("Export and share this document")
                        
                        // Save button (primary)
                        Button {
                            showSaveDocument = true
                        } label: {
                            Text("Save")
                                .font(NBType.body)
                                .foregroundStyle(NBColors.ink)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(NBColors.yellow)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                        }
                        .disabled(pages.isEmpty)
                    }
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
                                let isDragging = draggingPage?.id == page.id
                                let isTargeted = targetedPageId == page.id && !isDragging
                                
                                PageThumbnail(page: page, index: index, onEdit: {
                                    selectedPageIndex = index
                                }, onDelete: {
                                    sessionStore.removePage(at: index)
                                })
                                    .opacity(isDragging ? 0.4 : 1.0)
                                    .scaleEffect(isDragging ? 0.95 : (isTargeted ? 1.05 : 1.0))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: NBTheme.corner + 4)
                                            .stroke(NBColors.yellow, lineWidth: 3)
                                            .padding(-4)
                                            .opacity(isTargeted ? 1 : 0)
                                    )
                                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
                                    .animation(.easeInOut(duration: 0.15), value: isDragging)
                                    .draggable(page.id.uuidString) {
                                        // Drag preview
                                        PageThumbnailPreview(page: page, index: index)
                                            .onAppear {
                                                withAnimation(.easeInOut(duration: 0.15)) {
                                                    draggingPage = page
                                                }
                                            }
                                    }
                                    .dropDestination(for: String.self) { items, location in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            targetedPageId = nil
                                            draggingPage = nil
                                        }
                                        
                                        guard let droppedId = items.first,
                                              let droppedUUID = UUID(uuidString: droppedId),
                                              let sourceIndex = pages.firstIndex(where: { $0.id == droppedUUID }),
                                              let destinationIndex = pages.firstIndex(where: { $0.id == page.id }) else {
                                            return false
                                        }
                                        
                                        if sourceIndex != destinationIndex {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                sessionStore.reorderPages(from: IndexSet(integer: sourceIndex), to: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex)
                                            }
                                        }
                                        return true
                                    } isTargeted: { isTargeted in
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            targetedPageId = isTargeted ? page.id : (targetedPageId == page.id ? nil : targetedPageId)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, NBTheme.padding)
                        .padding(.top, 8)
                        .padding(.bottom, 100)
                    }
                    .onChange(of: draggingPage) { oldValue, newValue in
                        if newValue == nil {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                targetedPageId = nil
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showSaveDocument) {
            SaveDocumentView(sessionStore: sessionStore)
        }
        .navigationDestination(item: $selectedPageIndex) { index in
            if index < pages.count {
                PageEditView(page: pages[index], pageIndex: index, sessionStore: sessionStore)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareDocumentSheet(
                documentName: $shareDocumentName,
                selectedFormat: $shareFormat,
                pages: pages,
                onShare: { name, format in
                    shareDocument(name: name, format: format)
                }
            )
        }
        .alert("Export Failed", isPresented: $showExportErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Functions
    private func generateDefaultTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmm"
        return "Scan \(formatter.string(from: Date()))"
    }
    
    private func shareDocument(name: String, format: ExportShareFormat) {
        let exportName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !exportName.isEmpty else {
            exportErrorMessage = "Document name can’t be empty."
            showExportErrorAlert = true
            showShareSheet = false
            return
        }
        
        // Generate export items
        let items: [Any]
        switch format {
        case .pdf:
            guard let url = ExportService.generatePDF(from: pages, title: exportName, imageURLProvider: { $0.sourceImageURL }) else {
                exportErrorMessage = "Couldn’t generate the PDF. Please try again."
                showExportErrorAlert = true
                showShareSheet = false
                return
            }
            items = [url]
        case .images:
            let urls = ExportService.generateJPGs(from: pages, title: exportName, imageURLProvider: { $0.sourceImageURL })
            guard !urls.isEmpty else {
                exportErrorMessage = "Couldn’t generate images. Please try again."
                showExportErrorAlert = true
                showShareSheet = false
                return
            }
            items = urls
        case .text:
            guard let url = ExportService.generateTextFile(from: pages, title: exportName) else {
                exportErrorMessage = "Couldn’t generate the text file. Please try again."
                showExportErrorAlert = true
                showShareSheet = false
                return
            }
            items = [url]
        }
        
        // Present iOS share sheet FIRST, then dismiss our sheet in completion
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // Find the topmost presented view controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            
            let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            // Dismiss our sheet after share sheet is presented or dismissed
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                DispatchQueue.main.async {
                    self.showShareSheet = false
                }
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Page Thumbnail
struct PageThumbnail: View {
    let page: ScanPage
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    private var adjustedImage: UIImage? {
        guard let image = page.uiImage else { return nil }
        return ImageProcessingService.applyAdjustments(
            to: image,
            brightness: page.brightness,
            contrast: page.contrast,
            rotation: page.rotation
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: NBTheme.corner)
                    .fill(NBColors.warmCard)
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay(
                        Group {
                            if let image = adjustedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 32))
                                    .foregroundStyle(NBColors.mutedInk)
                                    .accessibilityHidden(true)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                    .overlay(
                        RoundedRectangle(cornerRadius: NBTheme.corner)
                            .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                    )
                
                // Delete button (top-left)
                VStack {
                    HStack {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(NBColors.ink)
                                .frame(width: 44, height: 44)
                                .background(Color(red: 1.0, green: 0.6, blue: 0.6))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                        }
                        .offset(x: -8, y: -8)
                        .accessibilityLabel("Delete page \(index + 1)")
                        .accessibilityHint("Deletes this page from the document")
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                // Edit button (top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            onEdit()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(NBColors.ink)
                                .frame(width: 44, height: 44)
                                .background(NBColors.yellow)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                        }
                        .offset(x: 8, y: -8)
                        .accessibilityLabel("Edit page \(index + 1)")
                        .accessibilityHint("Opens page editing")
                    }
                    Spacer()
                }
            }
            
            Text("Page \(index + 1)")
                .font(NBType.caption)
                .foregroundStyle(NBColors.ink)
        }
        .alert("Delete Page?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete page \(index + 1)? This action cannot be undone.")
        }
    }
}

// MARK: - Page Thumbnail Preview (for drag)
struct PageThumbnailPreview: View {
    let page: ScanPage
    let index: Int
    
    private var adjustedImage: UIImage? {
        guard let image = page.uiImage else { return nil }
        return ImageProcessingService.applyAdjustments(
            to: image,
            brightness: page.brightness,
            contrast: page.contrast,
            rotation: page.rotation
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: NBTheme.corner)
                .fill(NBColors.warmCard)
                .frame(width: 100, height: 133)
                .overlay(
                    Group {
                        if let image = adjustedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "doc.text")
                                .font(.system(size: 24))
                                .foregroundStyle(NBColors.mutedInk)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                .overlay(
                    RoundedRectangle(cornerRadius: NBTheme.corner)
                        .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                )
            
            Text("Page \(index + 1)")
                .font(NBType.caption)
                .foregroundStyle(NBColors.ink)
        }
    }
}

#Preview("PagesView") {
    NavigationStack {
        let store = ScanSessionStore()
        let _ = {
            store.startNewSession()
            if let image = UIImage(systemName: "doc.text") {
                store.addPage(image)
                store.addPage(image)
            }
        }()
        return PagesView(sessionStore: store)
    }
}

#Preview("PageThumbnail") {
    let page = ScanPage(uiImage: UIImage(systemName: "doc.text"))
    PageThumbnail(page: page, index: 0, onEdit: {}, onDelete: {})
        .frame(width: 150)
        .padding()
}

