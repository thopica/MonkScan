import Foundation
import UIKit

// MARK: - ScanPage
struct ScanPage: Identifiable {
    let id: UUID
    var uiImage: UIImage?
    var rotation: Int = 0
    
    init(id: UUID = UUID(), uiImage: UIImage? = nil, rotation: Int = 0) {
        self.id = id
        self.uiImage = uiImage
        self.rotation = rotation
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

