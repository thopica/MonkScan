import SwiftUI
import UIKit

struct SaveDocumentView: View {
    @ObservedObject var sessionStore: ScanSessionStore
    @EnvironmentObject var libraryStore: LibraryStore
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var documentTitle: String
    @State private var selectedTags: [String] = []
    @State private var showTagPicker = false
    @State private var isSaving = false
    
    @State private var showErrorAlert = false
    @State private var errorAlertTitle = ""
    @State private var errorAlertMessage = ""
    @State private var returnToLibraryAfterAlert = false
    
    init(sessionStore: ScanSessionStore) {
        self.sessionStore = sessionStore
        _documentTitle = State(initialValue: sessionStore.currentSession?.draftTitle ?? "")
    }
    
    private var pages: [ScanPage] {
        sessionStore.currentSession?.pages ?? []
    }
    
    var body: some View {
        NBScreen {
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
                    
                    Text("Save Document")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.ink)
                    
                    Spacer()
                    
                    // Invisible placeholder for centering
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .opacity(0)
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Document title
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Document Name")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                NBTextField(placeholder: "Enter title...", systemIcon: nil, text: $documentTitle)
                            }
                        }
                        
                        // Tags
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Tags")
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.ink)
                                    Spacer()
                                    Button {
                                        showTagPicker = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(NBColors.ink)
                                            .frame(width: 44, height: 44)
                                    }
                                    .accessibilityLabel("Add tag")
                                    .accessibilityHint("Opens tag picker")
                                }
                                
                                if selectedTags.isEmpty {
                                    Text("No tags added")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.mutedInk)
                                } else {
                                    FlowLayout(spacing: 8) {
                                        ForEach(selectedTags, id: \.self) { tag in
                                            TagChip(text: tag) {
                                                selectedTags.removeAll { $0 == tag }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Preview
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Preview")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(NBColors.paper)
                                                    .frame(width: 60, height: 80)
                                                
                                                if let image = page.uiImage {
                                                    let adjusted = ImageProcessingService.applyAdjustments(
                                                        to: image,
                                                        brightness: page.brightness,
                                                        contrast: page.contrast,
                                                        rotation: page.rotation
                                                    )
                                                    Image(uiImage: adjusted)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 60, height: 80)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                            }
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(NBColors.ink, lineWidth: 1)
                                            )
                                            .overlay(
                                                VStack {
                                                    Spacer()
                                                    Text("\(index + 1)")
                                                        .font(NBType.caption)
                                                        .foregroundStyle(NBColors.ink)
                                                        .padding(4)
                                                        .background(NBColors.yellow.opacity(0.9))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4)
                                            )
                                        }
                                    }
                                }
                                
                                Text("\(pages.count) page\(pages.count == 1 ? "" : "s")")
                                    .font(NBType.caption)
                                    .foregroundStyle(NBColors.mutedInk)
                            }
                        }
                        
                        Spacer().frame(height: 20)
                        
                        // Save to Library button
                        Button {
                            saveDocument(andShare: false)
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: NBColors.ink))
                                    Text("Saving...")
                                } else {
                                    Image(systemName: "folder.badge.plus")
                                    Text("Save to Library")
                                }
                            }
                            .font(NBType.body)
                            .foregroundStyle(NBColors.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(NBColors.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                            .overlay(
                                RoundedRectangle(cornerRadius: NBTheme.corner)
                                    .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving || documentTitle.isEmpty || pages.isEmpty)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTagPicker) {
            TagPickerView(selectedTags: $selectedTags)
        }
        .alert(errorAlertTitle, isPresented: $showErrorAlert) {
            Button("OK") {
                if returnToLibraryAfterAlert {
                    returnToLibraryAfterAlert = false
                    returnToLibrary()
                }
            }
        } message: {
            Text(errorAlertMessage)
        }
    }
    
    // MARK: - Save Document
    private func saveDocument(andShare: Bool, format: ExportShareFormat = .pdf) {
        guard !documentTitle.isEmpty, !pages.isEmpty else { return }
        
        isSaving = true
        
        Task {
            do {
                // Create document from session
                var session = sessionStore.currentSession!
                session.draftTitle = documentTitle
                session.draftTags = selectedTags
                let document = ScanDocument(from: session)
                
                // Save to library
                try await libraryStore.saveDocument(document)
                
                // Store pages for sharing before clearing session
                let pagesToShare = session.pages
                
                // Clear session
                sessionStore.clearSession()
                
                await MainActor.run {
                    isSaving = false
                    
                    if andShare {
                        // Share the document
                        shareDocument(title: documentTitle, pages: pagesToShare, format: format)
                    } else {
                        // Return to Library tab
                        returnToLibrary()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    returnToLibraryAfterAlert = false
                    showError(title: "Save Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func returnToLibrary() {
        // Switch to Library tab first to avoid showing intermediate views
        tabCoordinator.switchTo(.library)
        
        // Then dismiss both SaveDocumentView and PagesView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        }
    }
    
    private func shareDocument(title: String, pages: [ScanPage], format: ExportShareFormat) {
        let exportName = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !exportName.isEmpty else {
            returnToLibraryAfterAlert = true
            showError(title: "Export Failed", message: "Document name can’t be empty.")
            return
        }
        
        let items: [Any]
        switch format {
        case .pdf:
            guard let url = ExportService.generatePDF(from: pages, title: exportName, imageURLProvider: { $0.sourceImageURL }) else {
                returnToLibraryAfterAlert = true
                showError(title: "Export Failed", message: "Couldn’t generate the PDF. Please try again.")
                return
            }
            items = [url]
        case .images:
            let urls = ExportService.generateJPGs(from: pages, title: exportName, imageURLProvider: { $0.sourceImageURL })
            guard !urls.isEmpty else {
                returnToLibraryAfterAlert = true
                showError(title: "Export Failed", message: "Couldn’t generate images. Please try again.")
                return
            }
            items = urls
        case .text:
            guard let url = ExportService.generateTextFile(from: pages, title: exportName) else {
                returnToLibraryAfterAlert = true
                showError(title: "Export Failed", message: "Couldn’t generate the text file. Please try again.")
                return
            }
            items = [url]
        }
        
        // Show share sheet
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
                // Return to Library tab after sharing
                self.returnToLibrary()
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
    
    private func showError(title: String, message: String) {
        errorAlertTitle = title
        errorAlertMessage = message
        showErrorAlert = true
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(NBType.caption)
                .foregroundStyle(NBColors.ink)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(NBColors.ink.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(NBColors.yellow.opacity(0.5))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(NBColors.ink, lineWidth: 1))
    }
}

// MARK: - Tag Picker View
struct TagPickerView: View {
    @Binding var selectedTags: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var customTag = ""
    @State private var availableTags: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                NBColors.paper.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Custom tag input
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Add Custom Tag")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                HStack {
                                    NBTextField(placeholder: "Enter tag name...", text: $customTag)
                                    
                                    Button {
                                        if !customTag.isEmpty {
                                            let trimmedTag = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                            if !trimmedTag.isEmpty {
                                                // Add to TagService (persisted globally)
                                                TagService.addTag(trimmedTag)
                                                // Add to selected tags for this document
                                                if !selectedTags.contains(trimmedTag) {
                                                    selectedTags.append(trimmedTag)
                                                }
                                                customTag = ""
                                                // Reload available tags
                                                availableTags = TagService.loadTags()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundStyle(NBColors.yellow)
                                            .overlay(
                                                Circle()
                                                    .stroke(NBColors.ink, lineWidth: 2)
                                            )
                                    }
                                    .disabled(customTag.isEmpty)
                                }
                            }
                        }
                        
                        // All saved custom tags
                        if !availableTags.isEmpty {
                            NBCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("All Tags")
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.ink)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(availableTags, id: \.self) { tag in
                                            TagWithDeleteButton(
                                                tag: tag,
                                                isSelected: selectedTags.contains(tag),
                                                onSelect: {
                                                    if selectedTags.contains(tag) {
                                                        selectedTags.removeAll { $0 == tag }
                                                    } else {
                                                        selectedTags.append(tag)
                                                    }
                                                },
                                                onDelete: {
                                                    // Remove from global tags
                                                    TagService.deleteTag(tag)
                                                    // Remove from selected tags
                                                    selectedTags.removeAll { $0 == tag }
                                                    // Reload available tags
                                                    availableTags = TagService.loadTags()
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        } else {
                            NBCard {
                                VStack(spacing: 8) {
                                    Image(systemName: "tag")
                                        .font(.system(size: 40))
                                        .foregroundStyle(NBColors.mutedInk)
                                    Text("No tags yet")
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.mutedInk)
                                    Text("Create your first custom tag above")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.mutedInk)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                availableTags = TagService.loadTags()
            }
        }
    }
}

// MARK: - Tag With Delete Button
struct TagWithDeleteButton: View {
    let tag: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: onSelect) {
                HStack(spacing: 4) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                    }
                    Text(tag)
                        .font(NBType.caption)
                }
                .foregroundStyle(NBColors.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? NBColors.yellow : NBColors.warmCard)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(NBColors.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(NBColors.ink.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Flow Layout (for wrapping tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview("TagPickerView") {
    TagPickerView(selectedTags: .constant(["Receipt", "Business"]))
}

#Preview {
    let store = ScanSessionStore()
    let _ = {
        store.startNewSession()
        if let image = UIImage(systemName: "doc.text.fill") {
            store.addPage(image)
            store.addPage(image)
        }
    }()
    
    let documentStore = try! FileDocumentStore()
    let libraryStore = LibraryStore(documentStore: documentStore)
    
    return NavigationStack {
        SaveDocumentView(sessionStore: store)
            .environmentObject(libraryStore)
    }
}

