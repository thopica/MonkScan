import Foundation
import UIKit

// MARK: - ScanPage
struct ScanPage: Identifiable, Equatable {
    let id: UUID
    var uiImage: UIImage?
    var rotation: Int = 0
    
    init(id: UUID = UUID(), uiImage: UIImage? = nil, rotation: Int = 0) {
        self.id = id
        self.uiImage = uiImage
        self.rotation = rotation
    }
    
    static func == (lhs: ScanPage, rhs: ScanPage) -> Bool {
        lhs.id == rhs.id && lhs.rotation == rhs.rotation
    }
}

// MARK: - ScanSession
struct ScanSession {
    var draftTitle: String
    var draftTags: [String]
    var pages: [ScanPage]
    
    init(draftTitle: String? = nil, draftTags: [String] = [], pages: [ScanPage] = []) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmm"
        self.draftTitle = draftTitle ?? "Scan \(formatter.string(from: Date()))"
        self.draftTags = draftTags
        self.pages = pages
    }
}

