import SwiftUI

struct ExportView: View {
    @ObservedObject var sessionStore: ScanSessionStore
    @EnvironmentObject var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var documentTitle: String
    @State private var selectedTags: [String] = []
    @State private var showTagPicker = false
    @State private var showDoneAlert = false
    @State private var isSaving = false
    
    init(sessionStore: ScanSessionStore) {
        self.sessionStore = sessionStore
        _documentTitle = State(initialValue: sessionStore.currentSession?.draftTitle ?? "Scan")
    }
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case jpg = "JPG"
        case text = "Text"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .jpg: return "photo"
            case .text: return "doc.text"
            }
        }
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
                                
                                NBTextField(placeholder: "Enter title...", text: $documentTitle)
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
                                    }
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
                        
                        // Save button
                        Button {
                            saveDocument()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: NBColors.ink))
                                    Text("Saving...")
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
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
        .alert("Document Saved!", isPresented: $showDoneAlert) {
            Button("Go to Library") {
                // Pop all navigation and go to library
                dismiss()
                dismiss() // Dismiss ExportView and PagesView
            }
        } message: {
            Text("'\(documentTitle)' has been saved to your library.")
        }
    }
    
    // MARK: - Save Document
    private func saveDocument() {
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
                
                // Clear session
                sessionStore.clearSession()
                
                await MainActor.run {
                    isSaving = false
                    showDoneAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // TODO: Show error alert
                    print("Failed to save document: \(error)")
                }
            }
        }
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let format: ExportView.ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.system(size: 24))
                Text(format.rawValue)
                    .font(NBType.caption)
            }
            .foregroundStyle(NBColors.ink)
            .frame(width: 70, height: 70)
            .background(isSelected ? NBColors.yellow : NBColors.warmCard)
            .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
            .overlay(
                RoundedRectangle(cornerRadius: NBTheme.corner)
                    .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
            )
        }
        .buttonStyle(.plain)
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
                                        if !customTag.isEmpty && !selectedTags.contains(customTag) {
                                            selectedTags.append(customTag)
                                            customTag = ""
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
                        
                        // Predefined tags by category
                        ForEach(TagService.predefinedTags) { category in
                            NBCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(category.name)
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.ink)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(category.tags, id: \.self) { tag in
                                            TagSelectionButton(
                                                tag: tag,
                                                isSelected: selectedTags.contains(tag)
                                            ) {
                                                if selectedTags.contains(tag) {
                                                    selectedTags.removeAll { $0 == tag }
                                                } else {
                                                    selectedTags.append(tag)
                                                }
                                            }
                                        }
                                    }
                                }
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
        }
    }
}

// MARK: - Tag Selection Button
struct TagSelectionButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
        ExportView(sessionStore: store)
            .environmentObject(libraryStore)
    }
}

