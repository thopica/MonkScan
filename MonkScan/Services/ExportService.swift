import Foundation
import UIKit
import PDFKit
import OSLog

// MARK: - Export Service
class ExportService {
    private static let logger = Logger(subsystem: "com.thomas.MonkScan", category: "ExportService")
    
    // MARK: - Generate PDF from pages
    static func generatePDF(from pages: [ScanPage], title: String, imageURLProvider: ((ScanPage) -> URL?)? = nil) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MonkScan",
            kCGPDFContextTitle: title
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Use A4 size
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 in points
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let tempDir = FileManager.default.temporaryDirectory
        let pdfURL = tempDir.appendingPathComponent("\(title).pdf")
        
        do {
            try renderer.writePDF(to: pdfURL) { context in
                for page in pages {
                    autoreleasepool {
                        let baseImage: UIImage? = {
                            if let url = imageURLProvider?(page) {
                                return UIImage(contentsOfFile: url.path)
                            }
                            return page.uiImage
                        }()
                        
                        guard let image = baseImage else { return }
                        
                        // Apply adjustments
                        let adjustedImage = ImageProcessingService.applyAdjustments(
                            to: image,
                            brightness: page.brightness,
                            contrast: page.contrast,
                            rotation: page.rotation
                        )
                        
                        context.beginPage()
                        
                        // Calculate aspect fit
                        let imageAspect = adjustedImage.size.width / adjustedImage.size.height
                        let pageAspect = pageRect.width / pageRect.height
                        
                        var drawRect = pageRect
                        if imageAspect > pageAspect {
                            // Image is wider - fit to width
                            let height = pageRect.width / imageAspect
                            drawRect = CGRect(x: 0, y: (pageRect.height - height) / 2, width: pageRect.width, height: height)
                        } else {
                            // Image is taller - fit to height
                            let width = pageRect.height * imageAspect
                            drawRect = CGRect(x: (pageRect.width - width) / 2, y: 0, width: width, height: pageRect.height)
                        }
                        
                        adjustedImage.draw(in: drawRect)
                    }
                }
            }
            
            return pdfURL
        } catch {
            Self.logger.error("Failed to create PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Generate JPG images from pages
    static func generateJPGs(from pages: [ScanPage], title: String, imageURLProvider: ((ScanPage) -> URL?)? = nil) -> [URL] {
        var urls: [URL] = []
        let tempDir = FileManager.default.temporaryDirectory
        
        for (index, page) in pages.enumerated() {
            autoreleasepool {
                let baseImage: UIImage? = {
                    if let url = imageURLProvider?(page) {
                        return UIImage(contentsOfFile: url.path)
                    }
                    return page.uiImage
                }()
                
                guard let image = baseImage else { return }
                
                // Apply adjustments
                let adjustedImage = ImageProcessingService.applyAdjustments(
                    to: image,
                    brightness: page.brightness,
                    contrast: page.contrast,
                    rotation: page.rotation
                )
                
                guard let jpgData = adjustedImage.jpegData(compressionQuality: 0.9) else { return }
                
                let filename = pages.count > 1 ? "\(title)_\(index + 1).jpg" : "\(title).jpg"
                let fileURL = tempDir.appendingPathComponent(filename)
                
                do {
                    try jpgData.write(to: fileURL)
                    urls.append(fileURL)
                } catch {
                    Self.logger.error("Failed to write JPG: \(error.localizedDescription)")
                }
            }
        }
        
        return urls
    }
    
    // MARK: - Generate text file from OCR
    static func generateTextFile(from pages: [ScanPage], title: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let textURL = tempDir.appendingPathComponent("\(title).txt")
        
        var fullText = ""
        for (index, page) in pages.enumerated() {
            if let ocrText = page.ocrText, !ocrText.isEmpty {
                if index > 0 {
                    fullText += "\n\n--- Page \(index + 1) ---\n\n"
                }
                fullText += ocrText
            }
        }
        
        if fullText.isEmpty {
            fullText = "No text recognized in this document."
        }
        
        do {
            try fullText.write(to: textURL, atomically: true, encoding: .utf8)
            return textURL
        } catch {
            Self.logger.error("Failed to create text file: \(error.localizedDescription)")
            return nil
        }
    }
}

