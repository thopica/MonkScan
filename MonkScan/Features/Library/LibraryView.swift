import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryStore: LibraryStore
    @State private var query = ""
    @State private var selectedDocument: ScanDocument?
    @State private var showDeleteAlert = false
    @State private var documentToDelete: ScanDocument?
    @State private var navigateToDocument: ScanDocument?

    private var filteredDocuments: [ScanDocument] {
        libraryStore.searchDocuments(query: query)
    }

    var body: some View {
        NavigationStack {
            NBScreen {
                VStack(spacing: 14) {
                NBTopBar(
                    title: "MonkScan",
                    trailing: AnyView(
                        HStack(spacing: 12) {
                            if libraryStore.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            NBIconButton(systemName: "arrow.clockwise", filled: false) {
                                Task {
                                    await libraryStore.loadDocuments()
                                }
                            }
                        }
                    )
                )

                NBTextField(placeholder: "Search documents, tags, text…", text: $query)

                // Document count
                HStack {
                    Text("\(filteredDocuments.count) documents")
                        .font(NBType.body)
                        .foregroundStyle(NBColors.mutedInk)
                    Spacer()
                }
                .padding(.horizontal, NBTheme.padding)

                // Documents list
                if filteredDocuments.isEmpty && !libraryStore.isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundStyle(NBColors.mutedInk)
                        Text(query.isEmpty ? "No documents yet" : "No matching documents")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.mutedInk)
                        if query.isEmpty {
                            Text("Scan your first document!")
                                .font(NBType.caption)
                                .foregroundStyle(NBColors.mutedInk)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filteredDocuments) { doc in
                                DocumentRow(document: doc, onTap: {
                                    navigateToDocument = doc
                                }, onDelete: {
                                    documentToDelete = doc
                                    showDeleteAlert = true
                                })
                            }
                        }
                        .padding(.bottom, 90)
                    }
                }

                Spacer()
            }
            }
            .navigationDestination(item: $navigateToDocument) { doc in
                DocumentDetailView(documentId: doc.id)
            }
            .alert("Delete Document?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    documentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let doc = documentToDelete {
                        Task {
                            try? await libraryStore.deleteDocument(doc.id)
                        }
                    }
                    documentToDelete = nil
                }
            } message: {
                if let doc = documentToDelete {
                    Text("Are you sure you want to delete '\(doc.title)'? This action cannot be undone.")
                }
            }
        }
    }
}

// MARK: - Document Row
struct DocumentRow: View {
    let document: ScanDocument
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var subtitle: String {
        let pageCount = "\(document.pages.count) page\(document.pages.count == 1 ? "" : "s")"
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(pageCount) • \(formatter.string(from: document.updatedAt))"
    }
    
    private var thumbnail: UIImage? {
        document.pages.first?.uiImage
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(NBColors.warmCard)
                    .frame(width: 50, height: 66)
                
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "doc.text")
                        .font(.system(size: 20))
                        .foregroundStyle(NBColors.mutedInk)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
            )
            
            // Title and info
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(NBType.body)
                    .foregroundStyle(NBColors.ink)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(NBType.caption)
                    .foregroundStyle(NBColors.mutedInk)
                
                if !document.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(document.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(NBType.caption)
                                .foregroundStyle(NBColors.ink)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(NBColors.yellow.opacity(0.3))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(NBColors.ink, lineWidth: 1))
                        }
                        if document.tags.count > 3 {
                            Text("+\(document.tags.count - 3)")
                                .font(NBType.caption)
                                .foregroundStyle(NBColors.mutedInk)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NBColors.ink.opacity(0.6))
            }
            .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(NBColors.warmCard)
        .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
        .overlay(
            RoundedRectangle(cornerRadius: NBTheme.corner)
                .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
        )
        .padding(.horizontal, NBTheme.padding)
        .buttonStyle(.plain)
    }
}

#Preview {
    let documentStore = try! FileDocumentStore()
    let libraryStore = LibraryStore(documentStore: documentStore)
    return LibraryView()
        .environmentObject(libraryStore)
}
