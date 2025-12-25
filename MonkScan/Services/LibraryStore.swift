import Foundation
import SwiftUI
import Combine

// MARK: - LibraryStore (manages document library)
@MainActor
class LibraryStore: ObservableObject {
    @Published var documents: [ScanDocument] = []
    @Published var isLoading = false
    @Published var error: String?
    
    let documentStore: DocumentStore
    
    init(documentStore: DocumentStore) {
        self.documentStore = documentStore
    }
    
    // MARK: - Load Documents
    func loadDocuments() async {
        isLoading = true
        error = nil
        
        do {
            documents = try await documentStore.loadAll()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Save Document
    func saveDocument(_ document: ScanDocument) async throws {
        try await documentStore.save(document)
        await loadDocuments()
    }
    
    // MARK: - Update Document
    func updateDocument(_ document: ScanDocument) async throws {
        try await documentStore.update(document)
        await loadDocuments()
    }
    
    // MARK: - Delete Document
    func deleteDocument(_ documentId: UUID) async throws {
        try await documentStore.delete(documentId)
        await loadDocuments()
    }
    
    // MARK: - Search
    func searchDocuments(query: String) -> [ScanDocument] {
        guard !query.isEmpty else { return documents }
        
        return documents.filter { doc in
            doc.title.lowercased().contains(query.lowercased()) ||
            doc.tags.contains(where: { $0.lowercased().contains(query.lowercased()) }) ||
            doc.ocrText.lowercased().contains(query.lowercased())
        }
    }
}

