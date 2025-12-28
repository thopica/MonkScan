import Foundation
import UIKit

// MARK: - ScanPage
struct ScanPage: Identifiable, Equatable, Codable {
    let id: UUID
    var imagePath: String? // Path to saved image file
    var rotation: Int = 0
    var brightness: Double = 0.0
    var contrast: Double = 1.0
    var ocrText: String?
    
    // In-memory only (not persisted)
    var uiImage: UIImage?
    var sourceImageURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, imagePath, rotation, brightness, contrast, ocrText
    }
    
    init(id: UUID = UUID(), uiImage: UIImage? = nil, imagePath: String? = nil, rotation: Int = 0, brightness: Double = 0.0, contrast: Double = 1.0, ocrText: String? = nil, sourceImageURL: URL? = nil) {
        self.id = id
        self.uiImage = uiImage
        self.imagePath = imagePath
        self.rotation = rotation
        self.brightness = brightness
        self.contrast = contrast
        self.ocrText = ocrText
        self.sourceImageURL = sourceImageURL
    }
    
    // Codable conformance (uiImage excluded)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        rotation = try container.decode(Int.self, forKey: .rotation)
        brightness = try container.decode(Double.self, forKey: .brightness)
        contrast = try container.decode(Double.self, forKey: .contrast)
        ocrText = try container.decodeIfPresent(String.self, forKey: .ocrText)
        uiImage = nil // Will be loaded from disk when needed
        sourceImageURL = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(contrast, forKey: .contrast)
        try container.encodeIfPresent(ocrText, forKey: .ocrText)
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
        self.draftTitle = draftTitle ?? ""
        self.draftTags = draftTags
        self.pages = pages
    }
}

