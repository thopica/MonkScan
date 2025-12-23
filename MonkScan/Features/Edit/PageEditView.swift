import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct PageEditView: View {
    let page: ScanPage
    let pageIndex: Int
    @ObservedObject var sessionStore: ScanSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    
    var body: some View {
        ZStack {
            // Dark background for image viewing
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(NBType.body)
                        .foregroundStyle(NBColors.paper)
                    }
                    
                    Spacer()
                    
                    Text("Page \(pageIndex + 1)")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.paper)
                    
                    Spacer()
                    
                    // Delete button
                    Button {
                        sessionStore.removePage(at: pageIndex)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(NBColors.danger)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))
                
                // Full image view with sliders
                if let image = page.uiImage {
                    GeometryReader { geometry in
                        ZStack {
                            // Image fills most of the space
                            Image(uiImage: adjustedImage(from: image))
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                            
                            // Sliders and icons overlaid on the image
                            HStack {
                                VStack(spacing: 10) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(NBColors.yellow)
                                    VerticalSlider(value: $brightness, range: -1.0...1.0, color: NBColors.yellow, trackColor: NBColors.paper)
                                        .frame(width: 60, height: geometry.size.height * 0.78)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 10) {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(NBColors.yellow)
                                    VerticalSlider(value: $contrast, range: 0.5...2.0, color: NBColors.yellow, trackColor: NBColors.paper)
                                        .frame(width: 60, height: geometry.size.height * 0.78)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            
                            // Reset button at bottom center
                            VStack {
                                Spacer()
                                Button {
                                    brightness = 0.0
                                    contrast = 1.0
                                } label: {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(NBColors.ink)
                                        .padding(10)
                                        .background(NBColors.paper.opacity(0.9))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(NBColors.ink, lineWidth: 1))
                                }
                                .padding(.bottom, 12)
                            }
                        }
                    }
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundStyle(NBColors.mutedInk)
                        Text("No image")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.mutedInk)
                    }
                    Spacer()
                }
                
                // Bottom toolbar - placeholder for future editing controls
                HStack(spacing: 32) {
                    // Placeholder edit buttons (will be functional later)
                    EditToolButton(icon: "rotate.right", label: "Rotate")
                    EditToolButton(icon: "slider.horizontal.3", label: "Adjust")
                    EditToolButton(icon: "crop", label: "Crop")
                }
                .padding(.vertical, 20)
                .padding(.horizontal, NBTheme.padding)
                .background(Color.black.opacity(0.8))
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Image Adjustment
    private func adjustedImage(from image: UIImage) -> UIImage {
        // Fix orientation first - create a properly oriented image
        let orientedImage = fixImageOrientation(image)
        
        // If no adjustments needed, return oriented image
        if brightness == 0.0 && contrast == 1.0 {
            return orientedImage
        }
        
        guard let ciImage = CIImage(image: orientedImage) else { return orientedImage }
        
        let context = CIContext()
        let brightnessFilter = CIFilter.colorControls()
        brightnessFilter.inputImage = ciImage
        brightnessFilter.brightness = Float(brightness)
        brightnessFilter.contrast = Float(contrast)
        
        guard let outputImage = brightnessFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return orientedImage
        }
        
        // Return image with up orientation (already fixed)
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    // MARK: - Fix Image Orientation
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        // If image is already correctly oriented, return as-is
        if image.imageOrientation == .up {
            return image
        }
        
        // Create a new image with correct orientation
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
}

// MARK: - Vertical Slider (custom style)
struct VerticalSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let trackColor: Color
    
    // Styling
    private let trackWidth: CGFloat = 3     // slim track
    private let trackHeight: CGFloat = 420
    private let handleSize: CGFloat = 30    // ~17% smaller
    private let handleCutoutSize = CGSize(width: 16, height: 9)
    
    private var normalizedValue: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                Spacer(minLength: 12) // top padding
                
                ZStack(alignment: .top) {
                    // Track with rounded ends
                    RoundedRectangle(cornerRadius: trackWidth / 2)
                        .fill(trackColor)
                        .frame(width: trackWidth, height: trackHeight)
                    
                    // Handle
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: handleSize / 2)
                                .fill(color.opacity(0.9)) // softer tint
                                .frame(width: handleSize + 6, height: handleSize)
                                .shadow(color: Color.black.opacity(0.12), radius: 2, y: 1) // subtle shadow
                            
                            RoundedRectangle(cornerRadius: handleCutoutSize.height / 2)
                                .fill(Color.black.opacity(0.28))
                                .frame(width: handleCutoutSize.width, height: handleCutoutSize.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: handleCutoutSize.height / 2)
                                        .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                                )
                        }
                        .offset(y: normalizedValue * (trackHeight - handleSize))
                        
                        Spacer()
                    }
                    .frame(height: trackHeight, alignment: .top)
                }
                .frame(width: 60)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let trackTop = (geometry.size.height - trackHeight) / 2
                            let trackBottom = trackTop + trackHeight
                            let y = gesture.location.y
                            let clampedY = max(trackTop + handleSize / 2, min(trackBottom - handleSize / 2, y))
                            let normalized = (clampedY - trackTop - handleSize / 2) / (trackHeight - handleSize)
                            let target = range.lowerBound + Double(normalized) * (range.upperBound - range.lowerBound)
                            // Smooth granular response
                            value += (target - value) * 0.2
                        }
                )
                
                Spacer(minLength: 12) // bottom padding
            }
        }
    }
}

// MARK: - Edit Tool Button
struct EditToolButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(NBColors.paper.opacity(0.5))
            Text(label)
                .font(NBType.caption)
                .foregroundStyle(NBColors.paper.opacity(0.5))
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    let store = ScanSessionStore()
    let _ = {
        store.startNewSession()
        if let image = UIImage(systemName: "doc.text.fill") {
            store.addPage(image)
        }
    }()
    
    if let page = store.currentSession?.pages.first {
        return PageEditView(page: page, pageIndex: 0, sessionStore: store)
    } else {
        return Text("No page")
    }
}

