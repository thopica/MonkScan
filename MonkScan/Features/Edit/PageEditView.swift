import SwiftUI

struct PageEditView: View {
    let page: ScanPage
    let pageIndex: Int
    @ObservedObject var sessionStore: ScanSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var brightness: Double
    @State private var contrast: Double
    @State private var pendingRotation: Int
    @State private var showOCRResults = false
    @State private var isProcessingOCR = false
    @State private var ocrText: String?
    @State private var ocrError: String?
    
    private let ocrService: OCRService = VisionOCRService()
    
    init(page: ScanPage, pageIndex: Int, sessionStore: ScanSessionStore) {
        self.page = page
        self.pageIndex = pageIndex
        self.sessionStore = sessionStore
        _brightness = State(initialValue: page.brightness)
        _contrast = State(initialValue: page.contrast)
        _pendingRotation = State(initialValue: page.rotation)
    }
    
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
                    
                    // Save button
                    Button {
                        saveChanges()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(NBColors.yellow)
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
                
                 // Bottom toolbar - editing controls
                 HStack(spacing: 32) {
                     Button {
                         withAnimation(.none) {
                             pendingRotation = (pendingRotation + 90) % 360
                         }
                     } label: {
                         EditToolButton(icon: "rotate.right", label: "Rotate")
                     }
                     .buttonStyle(.plain)
                    
                    EditToolButton(icon: "slider.horizontal.3", label: "Adjust")
                    
                    Button {
                        performOCR()
                    } label: {
                        if isProcessingOCR {
                            VStack(spacing: 6) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: NBColors.yellow))
                                    .scaleEffect(0.8)
                                Text("OCR")
                                    .font(NBType.caption)
                                    .foregroundStyle(NBColors.paper.opacity(0.5))
                            }
                            .frame(minWidth: 60)
                        } else {
                            EditToolButton(icon: "doc.text.viewfinder", label: "OCR")
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessingOCR)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, NBTheme.padding)
                .background(Color.black.opacity(0.8))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showOCRResults) {
            if let ocrText = ocrText {
                OCRResultsView(ocrText: ocrText)
            }
        }
        .alert("OCR Error", isPresented: .constant(ocrError != nil)) {
            Button("OK") {
                ocrError = nil
            }
        } message: {
            if let error = ocrError {
                Text(error)
            }
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        sessionStore.updatePage(
            at: pageIndex,
            rotation: pendingRotation,
            brightness: brightness,
            contrast: contrast
        )
    }
    
    // MARK: - Image Adjustment
    private func adjustedImage(from image: UIImage) -> UIImage {
        return ImageProcessingService.applyAdjustments(
            to: image,
            brightness: brightness,
            contrast: contrast,
            rotation: pendingRotation
        )
    }
    
    // MARK: - OCR
    private func performOCR() {
        guard let image = page.uiImage else {
            ocrError = "No image available"
            return
        }
        
        isProcessingOCR = true
        ocrError = nil
        
        Task {
            do {
                // Apply current adjustments to image before OCR
                let processedImage = adjustedImage(from: image)
                let recognizedText = try await ocrService.recognizeText(from: processedImage)
                
                await MainActor.run {
                    ocrText = recognizedText
                    sessionStore.updatePageOCRText(at: pageIndex, ocrText: recognizedText)
                    isProcessingOCR = false
                    showOCRResults = true
                }
            } catch {
                await MainActor.run {
                    isProcessingOCR = false
                    ocrError = error.localizedDescription
                }
            }
        }
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

