import Foundation
import UIKit

// MARK: - ScanDocument (persisted document)
struct ScanDocument: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var pages: [ScanPage]
    
    // Computed: aggregated OCR text from all pages
    var ocrText: String {
        pages.compactMap { $0.ocrText }.joined(separator: "\n\n")
    }
    
    init(id: UUID = UUID(), 
         title: String, 
         createdAt: Date = Date(), 
         updatedAt: Date = Date(), 
         tags: [String] = [], 
         pages: [ScanPage] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.pages = pages
    }
    
    // Create from ScanSession
    init(from session: ScanSession) {
        self.id = UUID()
        self.title = session.draftTitle
        self.createdAt = Date()
        self.updatedAt = Date()
        self.tags = session.draftTags
        self.pages = session.pages
    }
    
    static func == (lhs: ScanDocument, rhs: ScanDocument) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Helper Models for Library UI
struct ScanFolder: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct ScanDoc: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let stars: Int
}
