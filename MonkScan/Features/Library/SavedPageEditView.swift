import SwiftUI

struct SavedPageEditView: View {
    let documentId: UUID
    let pageIndex: Int
    @EnvironmentObject var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var document: ScanDocument?
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var pendingRotation: Int = 0
    @State private var isSaving = false
    @State private var hasChanges = false
    @State private var showDiscardAlert = false
    @State private var showOCRResults = false
    @State private var isProcessingOCR = false
    @State private var ocrText: String?
    @State private var ocrError: String?
    @State private var saveError: String?
    
    private let ocrService: OCRService = VisionOCRService()
    
    private var page: ScanPage? {
        guard let doc = document,
              pageIndex >= 0,
              pageIndex < doc.pages.count else { return nil }
        return doc.pages[pageIndex]
    }
    
    var body: some View {
        ZStack {
            // Dark background for image viewing
            Color.black.ignoresSafeArea()
            
            if let page = page {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            if hasChanges {
                                showDiscardAlert = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Cancel")
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
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: NBColors.yellow))
                                    .scaleEffect(0.8)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Save")
                                }
                                .foregroundStyle(hasChanges ? NBColors.yellow : NBColors.paper.opacity(0.5))
                            }
                        }
                        .disabled(!hasChanges || isSaving)
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
                                            .onChange(of: brightness) { _, _ in hasChanges = true }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(spacing: 10) {
                                        Image(systemName: "circle.lefthalf.filled")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(NBColors.yellow)
                                        VerticalSlider(value: $contrast, range: 0.5...2.0, color: NBColors.yellow, trackColor: NBColors.paper)
                                            .frame(width: 60, height: geometry.size.height * 0.78)
                                            .onChange(of: contrast) { _, _ in hasChanges = true }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                
                                // Reset button at bottom center
                                VStack {
                                    Spacer()
                                    Button {
                                        resetToOriginal()
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
                                hasChanges = true
                            }
                        } label: {
                            EditToolButton(icon: "rotate.right", label: "Rotate")
                        }
                        .buttonStyle(.plain)
                        
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
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: NBColors.yellow))
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadDocument()
        }
        .sheet(isPresented: $showOCRResults) {
            if let ocrText = ocrText {
                OCRResultsView(ocrText: ocrText)
            }
        }
        .alert("Save Failed", isPresented: .constant(saveError != nil)) {
            Button("OK") {
                saveError = nil
            }
        } message: {
            if let error = saveError {
                Text(error)
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
        .alert("Discard Changes?", isPresented: $showDiscardAlert) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
    }
    
    // MARK: - Load Document
    private func loadDocument() {
        Task {
            if let docs = try? await libraryStore.documentStore.loadAll() {
                document = docs.first { $0.id == documentId }
                
                // Initialize values from page
                if let page = page {
                    brightness = page.brightness
                    contrast = page.contrast
                    pendingRotation = page.rotation
                }
            }
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        guard var doc = document,
              pageIndex >= 0,
              pageIndex < doc.pages.count else { return }
        
        isSaving = true
        hasChanges = false
        
        Task {
            // Update the page
            doc.pages[pageIndex].rotation = pendingRotation
            doc.pages[pageIndex].brightness = brightness
            doc.pages[pageIndex].contrast = contrast
            
            do {
                try await libraryStore.updateDocument(doc)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    hasChanges = true // Restore changes flag on error
                    saveError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Reset to Original
    private func resetToOriginal() {
        if let page = page {
            brightness = page.brightness
            contrast = page.contrast
            pendingRotation = page.rotation
            hasChanges = false
        }
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
        guard let page = page, let image = page.uiImage else {
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
                    isProcessingOCR = false
                    showOCRResults = true
                    
                    // Update the document with OCR text
                    if var doc = document,
                       pageIndex >= 0,
                       pageIndex < doc.pages.count {
                        doc.pages[pageIndex].ocrText = recognizedText
                        Task {
                            try? await libraryStore.updateDocument(doc)
                        }
                    }
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

#Preview {
    let documentStore = try! FileDocumentStore()
    let libraryStore = LibraryStore(documentStore: documentStore)
    
    // Create a sample document
    let sampleDoc = ScanDocument(
        title: "Sample Document",
        tags: ["Receipt"],
        pages: [ScanPage(uiImage: UIImage(systemName: "doc.text.fill"))]
    )
    
    Task {
        try? await libraryStore.saveDocument(sampleDoc)
    }
    
    return NavigationStack {
        SavedPageEditView(documentId: sampleDoc.id, pageIndex: 0)
            .environmentObject(libraryStore)
    }
}

