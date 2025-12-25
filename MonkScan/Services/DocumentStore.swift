import Foundation
import UIKit

// MARK: - DocumentStore Protocol
protocol DocumentStore {
    func save(_ document: ScanDocument) async throws
    func loadAll() async throws -> [ScanDocument]
    func delete(_ documentId: UUID) async throws
    func update(_ document: ScanDocument) async throws
}

// MARK: - Document Store Error
enum DocumentStoreError: LocalizedError {
    case directoryCreationFailed
    case imageSaveFailed(String)
    case metadataSaveFailed(String)
    case documentNotFound
    case imageLoadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "Failed to create document directory"
        case .imageSaveFailed(let reason):
            return "Failed to save image: \(reason)"
        case .metadataSaveFailed(let reason):
            return "Failed to save metadata: \(reason)"
        case .documentNotFound:
            return "Document not found"
        case .imageLoadFailed(let reason):
            return "Failed to load image: \(reason)"
        }
    }
}

// MARK: - FileDocumentStore
@MainActor
class FileDocumentStore: DocumentStore {
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    
    init() throws {
        // Get Documents directory
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DocumentStoreError.directoryCreationFailed
        }
        
        // Create MonkScan directory
        baseDirectory = documentsDir.appendingPathComponent("MonkScan", isDirectory: true)
        
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Document
    func save(_ document: ScanDocument) async throws {
        let docDirectory = baseDirectory.appendingPathComponent(document.id.uuidString, isDirectory: true)
        
        // Create document directory
        if !fileManager.fileExists(atPath: docDirectory.path) {
            try fileManager.createDirectory(at: docDirectory, withIntermediateDirectories: true)
        }
        
        // Save all page images and update paths
        var updatedPages: [ScanPage] = []
        for page in document.pages {
            var updatedPage = page
            
            // Save image if available and not already saved
            if let image = page.uiImage, page.imagePath == nil {
                let imageName = "\(page.id.uuidString).jpg"
                let imagePath = docDirectory.appendingPathComponent(imageName)
                
                guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                    throw DocumentStoreError.imageSaveFailed("Failed to convert image to JPEG")
                }
                
                try imageData.write(to: imagePath)
                updatedPage.imagePath = imageName
            }
            
            updatedPages.append(updatedPage)
        }
        
        // Create updated document with image paths
        var updatedDocument = document
        updatedDocument.pages = updatedPages
        
        // Save metadata as JSON
        let metadataPath = docDirectory.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(updatedDocument)
            try jsonData.write(to: metadataPath)
        } catch {
            throw DocumentStoreError.metadataSaveFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Load All Documents
    func loadAll() async throws -> [ScanDocument] {
        var documents: [ScanDocument] = []
        
        // Get all document directories
        let contents = try fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil)
        let docDirectories = contents.filter { $0.hasDirectoryPath }
        
        for docDir in docDirectories {
            let metadataPath = docDir.appendingPathComponent("metadata.json")
            
            guard fileManager.fileExists(atPath: metadataPath.path) else {
                continue
            }
            
            // Load metadata
            let jsonData = try Data(contentsOf: metadataPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            var document = try decoder.decode(ScanDocument.self, from: jsonData)
            
            // Load images for pages
            var loadedPages: [ScanPage] = []
            for page in document.pages {
                var loadedPage = page
                
                if let imagePath = page.imagePath {
                    let fullImagePath = docDir.appendingPathComponent(imagePath)
                    if fileManager.fileExists(atPath: fullImagePath.path),
                       let imageData = try? Data(contentsOf: fullImagePath),
                       let image = UIImage(data: imageData) {
                        loadedPage.uiImage = image
                    }
                }
                
                loadedPages.append(loadedPage)
            }
            
            document.pages = loadedPages
            documents.append(document)
        }
        
        // Sort by most recent first
        return documents.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Update Document
    func update(_ document: ScanDocument) async throws {
        // Update is same as save (overwrites existing)
        var updatedDoc = document
        updatedDoc.updatedAt = Date()
        try await save(updatedDoc)
    }
    
    // MARK: - Delete Document
    func delete(_ documentId: UUID) async throws {
        let docDirectory = baseDirectory.appendingPathComponent(documentId.uuidString, isDirectory: true)
        
        guard fileManager.fileExists(atPath: docDirectory.path) else {
            throw DocumentStoreError.documentNotFound
        }
        
        try fileManager.removeItem(at: docDirectory)
    }
    
    // MARK: - Helper: Load Single Document
    func loadDocument(_ documentId: UUID) async throws -> ScanDocument {
        let docDirectory = baseDirectory.appendingPathComponent(documentId.uuidString, isDirectory: true)
        let metadataPath = docDirectory.appendingPathComponent("metadata.json")
        
        guard fileManager.fileExists(atPath: metadataPath.path) else {
            throw DocumentStoreError.documentNotFound
        }
        
        let jsonData = try Data(contentsOf: metadataPath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var document = try decoder.decode(ScanDocument.self, from: jsonData)
        
        // Load images
        var loadedPages: [ScanPage] = []
        for page in document.pages {
            var loadedPage = page
            
            if let imagePath = page.imagePath {
                let fullImagePath = docDirectory.appendingPathComponent(imagePath)
                if fileManager.fileExists(atPath: fullImagePath.path),
                   let imageData = try? Data(contentsOf: fullImagePath),
                   let image = UIImage(data: imageData) {
                    loadedPage.uiImage = image
                }
            }
            
            loadedPages.append(loadedPage)
        }
        
        document.pages = loadedPages
        return document
    }
}

