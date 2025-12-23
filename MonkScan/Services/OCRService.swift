import Foundation
import UIKit
import Vision

// MARK: - OCRService Protocol
protocol OCRService {
    func recognizeText(from image: UIImage) async throws -> String
}

// MARK: - OCR Error
enum OCRError: LocalizedError {
    case noImage
    case noTextFound
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noImage:
            return "No image provided for text recognition"
        case .noTextFound:
            return "No text was found in the image"
        case .recognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        }
    }
}

// MARK: - VisionOCRService
class VisionOCRService: OCRService {
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.noImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                // Extract text from all observations
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure request for best accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
}

