import Foundation
import SwiftUI
import Combine

@MainActor
class ScanSessionStore: ObservableObject {
    @Published var currentSession: ScanSession?
    
    private let previewMaxPixelSize: CGFloat = 2000
    
    func startNewSession() {
        currentSession = ScanSession()
    }
    
    func addPage(_ image: UIImage) {
        if currentSession == nil {
            startNewSession()
        }
        
        // Write full-res to a temp file for high-quality export, keep only a downsampled preview in memory.
        let pageId = UUID()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("scan-\(pageId.uuidString).jpg")
        if let data = image.jpegData(compressionQuality: 0.95) {
            try? data.write(to: tempURL, options: .atomic)
        }
        
        let previewImage = ImageProcessingService.downsampledImage(at: tempURL, maxPixelSize: previewMaxPixelSize) ?? image
        let page = ScanPage(id: pageId, uiImage: previewImage, sourceImageURL: tempURL)
        currentSession?.pages.append(page)
    }
    
    func removePage(at index: Int) {
        guard var session = currentSession,
              index >= 0 && index < session.pages.count else { return }
        session.pages.remove(at: index)
        currentSession = session
    }
    
    func rotatePage(at index: Int) {
        guard var session = currentSession,
              index >= 0 && index < session.pages.count else { return }
        session.pages[index].rotation = (session.pages[index].rotation + 90) % 360
        currentSession = session
    }
    
    func reorderPages(from source: IndexSet, to destination: Int) {
        guard var session = currentSession else { return }
        session.pages.move(fromOffsets: source, toOffset: destination)
        currentSession = session
    }
    
    func updatePage(at index: Int, rotation: Int, brightness: Double, contrast: Double) {
        guard var session = currentSession,
              index >= 0 && index < session.pages.count else { return }
        session.pages[index].rotation = rotation
        session.pages[index].brightness = brightness
        session.pages[index].contrast = contrast
        currentSession = session
    }
    
    func updatePageOCRText(at index: Int, ocrText: String) {
        guard var session = currentSession,
              index >= 0 && index < session.pages.count else { return }
        session.pages[index].ocrText = ocrText
        currentSession = session
    }
    
    func clearSession() {
        currentSession = nil
    }
}

