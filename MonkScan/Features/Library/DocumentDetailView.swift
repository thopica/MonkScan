import SwiftUI

struct DocumentDetailView: View {
    let documentId: UUID
    @EnvironmentObject var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var document: ScanDocument?
    @State private var showEditMetadata = false
    @State private var selectedPageIndex: Int?
    @State private var showShareSheet = false
    @State private var shareFormat: ExportShareFormat = .pdf
    
    @State private var activeAlert: ActiveAlert?
    
    private enum ActiveAlert: Identifiable {
        case deleteDocument
        case exportFailed(message: String)
        
        var id: String {
            switch self {
            case .deleteDocument:
                return "deleteDocument"
            case .exportFailed(let message):
                return "exportFailed-\(message)"
            }
        }
    }
    
    var body: some View {
        Group {
            if let document = document {
                documentDetailContent(for: document)
            } else {
                ProgressView()
                    .onAppear {
                        loadDocument()
                    }
            }
        }
    }
    
    @ViewBuilder
    private func documentDetailContent(for document: ScanDocument) -> some View {
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
                            Text("Library")
                        }
                        .font(NBType.body)
                        .foregroundStyle(NBColors.ink)
                    }
                    
                    Spacer()
                    
                    // Actions menu
                    Menu {
                        Button {
                            showEditMetadata = true
                        } label: {
                            Label("Edit Name & Tags", systemImage: "pencil")
                        }
                        
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Export & Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            activeAlert = .deleteDocument
                        } label: {
                            Label("Delete Document", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(NBColors.ink)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("More actions")
                    .accessibilityHint("Shows document actions like export and delete")
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                
                // Document info
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and metadata
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(document.title)
                                    .font(NBType.header)
                                    .foregroundStyle(NBColors.ink)
                                
                                HStack {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14))
                                    Text("\(document.pages.count) page\(document.pages.count == 1 ? "" : "s")")
                                        .font(NBType.caption)
                                    
                                    Text("•")
                                        .font(NBType.caption)
                                    
                                    Text(formattedDate(document.updatedAt))
                                        .font(NBType.caption)
                                }
                                .foregroundStyle(NBColors.mutedInk)
                                
                                if !document.tags.isEmpty {
                                    Divider()
                                        .background(NBColors.ink.opacity(0.2))
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(document.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(NBType.caption)
                                                .foregroundStyle(NBColors.ink)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(NBColors.yellow.opacity(0.5))
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(NBColors.ink, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Pages section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pages")
                                .font(NBType.body)
                                .foregroundStyle(NBColors.ink)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                            ], spacing: 16) {
                                ForEach(Array(document.pages.enumerated()), id: \.element.id) { index, page in
                                    DocumentPageThumbnail(page: page, index: index) {
                                        selectedPageIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .padding(.horizontal, NBTheme.padding)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedPageIndex) { index in
            SavedPageEditView(documentId: documentId, pageIndex: index)
        }
        .sheet(isPresented: $showEditMetadata, onDismiss: {
            loadDocument() // Reload after editing
        }) {
            EditMetadataView(document: document)
        }
        .sheet(isPresented: $showShareSheet) {
            if let doc = self.document {
                ShareDocumentSheet(
                    documentName: .constant(doc.title),
                    selectedFormat: $shareFormat,
                    pages: doc.pages,
                    allowNameEditing: false,
                    onShare: { name, format in
                        shareDocument(document: doc, format: format)
                    }
                )
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .deleteDocument:
                return Alert(
                    title: Text("Delete Document?"),
                    message: Text("Are you sure you want to delete '\(document.title)'? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            try? await libraryStore.deleteDocument(document.id)
                            dismiss()
                        }
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            case .exportFailed(let message):
                return Alert(
                    title: Text("Export Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Load Document
    private func loadDocument() {
        Task {
            if let docs = try? await libraryStore.documentStore.loadAll() {
                document = docs.first { $0.id == documentId }
            }
        }
    }
    
    // MARK: - Helpers
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func shareDocument(document: ScanDocument, format: ExportShareFormat) {
        let exportName = document.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !exportName.isEmpty else {
            activeAlert = .exportFailed(message: "Document name can’t be empty.")
            showShareSheet = false
            return
        }
        
        // Generate export items
        let items: [Any]
        switch format {
        case .pdf:
            guard let url = ExportService.generatePDF(
                from: document.pages,
                title: exportName,
                imageURLProvider: { page in
                    guard let imagePath = page.imagePath else { return nil }
                    return libraryStore.documentStore.imageFileURL(documentId: document.id, imagePath: imagePath)
                }
            ) else {
                activeAlert = .exportFailed(message: "Couldn’t generate the PDF. Please try again.")
                showShareSheet = false
                return
            }
            items = [url]
        case .images:
            let urls = ExportService.generateJPGs(
                from: document.pages,
                title: exportName,
                imageURLProvider: { page in
                    guard let imagePath = page.imagePath else { return nil }
                    return libraryStore.documentStore.imageFileURL(documentId: document.id, imagePath: imagePath)
                }
            )
            guard !urls.isEmpty else {
                activeAlert = .exportFailed(message: "Couldn’t generate images. Please try again.")
                showShareSheet = false
                return
            }
            items = urls
        case .text:
            guard let url = ExportService.generateTextFile(from: document.pages, title: exportName) else {
                activeAlert = .exportFailed(message: "Couldn’t generate the text file. Please try again.")
                showShareSheet = false
                return
            }
            items = [url]
        }
        
        // Present iOS share sheet
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
            
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                DispatchQueue.main.async {
                    self.showShareSheet = false
                }
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Document Page Thumbnail
struct DocumentPageThumbnail: View {
    let page: ScanPage
    let index: Int
    let onTap: () -> Void
    
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
        Button(action: onTap) {
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
                    
                    // Edit indicator
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(NBColors.yellow)
                                .background(
                                    Circle()
                                        .fill(NBColors.ink)
                                        .frame(width: 24, height: 24)
                                )
                        }
                        .padding(8)
                        Spacer()
                    }
                }
                
                Text("Page \(index + 1)")
                    .font(NBType.caption)
                    .foregroundStyle(NBColors.ink)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Page \(index + 1)")
        .accessibilityHint("Opens page editing")
    }
}

#Preview {
    let documentStore = try! FileDocumentStore()
    let libraryStore = LibraryStore(documentStore: documentStore)
    
    // Create a sample document and save it
    let sampleDoc = ScanDocument(
        title: "Sample Document",
        tags: ["Receipt", "Business", "2024"],
        pages: [
            ScanPage(uiImage: UIImage(systemName: "doc.text.fill")),
            ScanPage(uiImage: UIImage(systemName: "doc.text.fill"))
        ]
    )
    
    Task {
        try? await libraryStore.saveDocument(sampleDoc)
    }
    
    return NavigationStack {
        DocumentDetailView(documentId: sampleDoc.id)
            .environmentObject(libraryStore)
    }
}

