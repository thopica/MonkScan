import Foundation
import UIKit

// MARK: - ScanPage
struct ScanPage: Identifiable, Equatable {
    let id: UUID
    var uiImage: UIImage?
    var rotation: Int = 0
    var brightness: Double = 0.0
    var contrast: Double = 1.0
    var ocrText: String?
    
    init(id: UUID = UUID(), uiImage: UIImage? = nil, rotation: Int = 0, brightness: Double = 0.0, contrast: Double = 1.0, ocrText: String? = nil) {
        self.id = id
        self.uiImage = uiImage
        self.rotation = rotation
        self.brightness = brightness
        self.contrast = contrast
        self.ocrText = ocrText
    }
    
    static func == (lhs: ScanPage, rhs: ScanPage) -> Bool {
        lhs.id == rhs.id && 
        lhs.rotation == rhs.rotation && 
        lhs.brightness == rhs.brightness && 
        lhs.contrast == rhs.contrast &&
        lhs.ocrText == rhs.ocrText
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

