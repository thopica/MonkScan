import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO

/// Service for applying image adjustments (brightness, contrast, rotation)
enum ImageProcessingService {
    
    /// Load a downsampled image from disk to reduce memory usage.
    /// Uses ImageIO thumbnail generation so we never decode the full-resolution image into memory.
    static func downsampledImage(at url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }
        
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// Apply brightness, contrast, and rotation to an image
    static func applyAdjustments(
        to image: UIImage,
        brightness: Double,
        contrast: Double,
        rotation: Int
    ) -> UIImage {
        // Fix orientation first
        var processedImage = fixImageOrientation(image)
        
        // Apply rotation if needed
        if rotation != 0 {
            processedImage = rotateImage(processedImage, by: rotation)
        }
        
        // Apply brightness/contrast if needed
        if brightness != 0.0 || contrast != 1.0 {
            processedImage = applyColorAdjustments(processedImage, brightness: brightness, contrast: contrast)
        }
        
        return processedImage
    }
    
    // MARK: - Private Helpers
    
    private static func applyColorAdjustments(_ image: UIImage, brightness: Double, contrast: Double) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext()
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = Float(brightness)
        filter.contrast = Float(contrast)
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    private static func rotateImage(_ image: UIImage, by degrees: Int) -> UIImage {
        guard degrees != 0 else { return image }
        guard let cgImage = image.cgImage else { return image }
        
        let radians = CGFloat(degrees) * .pi / 180.0
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        // Calculate new size (swap for 90/270 degree rotations)
        let newWidth = (degrees % 180 == 0) ? width : height
        let newHeight = (degrees % 180 == 0) ? height : width
        
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = cgImage.bitmapInfo.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: Int(newWidth),
            height: Int(newHeight),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return image
        }
        
        context.translateBy(x: newWidth / 2, y: newHeight / 2)
        context.rotate(by: radians)
        context.translateBy(x: -width / 2, y: -height / 2)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let rotatedCGImage = context.makeImage() else {
            return image
        }
        
        return UIImage(cgImage: rotatedCGImage, scale: image.scale, orientation: .up)
    }
    
    private static func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
}


