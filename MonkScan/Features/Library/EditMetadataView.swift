import SwiftUI

struct EditMetadataView: View {
    let document: ScanDocument
    @EnvironmentObject var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var documentTitle: String
    @State private var selectedTags: [String]
    @State private var showTagPicker = false
    @State private var isSaving = false
    
    init(document: ScanDocument) {
        self.document = document
        _documentTitle = State(initialValue: document.title)
        _selectedTags = State(initialValue: document.tags)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                NBColors.paper.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Document title and info
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Document Name")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                NBTextField(placeholder: "Enter title...", systemIcon: nil, text: $documentTitle)
                                
                                // Document info
                                Divider()
                                    .background(NBColors.ink.opacity(0.2))
                                    .padding(.vertical, 4)
                                
                                HStack {
                                    Text("Pages:")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.mutedInk)
                                    Text("\(document.pages.count)")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.ink)
                                }
                                
                                HStack {
                                    Text("Created:")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.mutedInk)
                                    Text(formattedDate(document.createdAt))
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.ink)
                                }
                                
                                HStack {
                                    Text("Last Modified:")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.mutedInk)
                                    Text(formattedDate(document.updatedAt))
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.ink)
                                }
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
                    }
                    .padding(.horizontal, NBTheme.padding)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(documentTitle.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        guard !documentTitle.isEmpty else { return }
        
        isSaving = true
        
        Task {
            var updatedDocument = document
            updatedDocument.title = documentTitle
            updatedDocument.tags = selectedTags
            
            do {
                try await libraryStore.updateDocument(updatedDocument)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    // TODO: Show error
                    print("Failed to update document: \(error)")
                }
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
}

#Preview {
    let documentStore = try! FileDocumentStore()
    let libraryStore = LibraryStore(documentStore: documentStore)
    
    let sampleDoc = ScanDocument(
        title: "Sample Document",
        tags: ["Receipt", "Business"],
        pages: [ScanPage(uiImage: UIImage(systemName: "doc.text.fill"))]
    )
    
    return EditMetadataView(document: sampleDoc)
        .environmentObject(libraryStore)
}

