import SwiftUI
import PhotosUI
import VisionKit

struct ScanView: View {
    @StateObject private var sessionStore = ScanSessionStore()
    @State private var showPages = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showDocumentScanner = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                NBColors.paper.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top section with GIF - centered, small
                    AnimatedGifView(name: "scanviewmonk", size: CGSize(width: 550, height: 500))
                        .frame(width: 150, height: 150)
                        .padding(.top, 160)
                    
                    Spacer(minLength: 20)
                    
                    // Bottom section - Action buttons (fixed at bottom)
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Photo import button
                            PhotosPicker(selection: $selectedPhotoItems, maxSelectionCount: nil, matching: .images) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 32, weight: .bold))
                                    Text("Import")
                                        .font(NBType.body)
                                }
                                .foregroundStyle(NBColors.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(NBColors.warmCard)
                                .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                                .overlay(
                                    RoundedRectangle(cornerRadius: NBTheme.corner)
                                        .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Start scan button
                            Button {
                                showDocumentScanner = true
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text.viewfinder")
                                        .font(.system(size: 32, weight: .bold))
                                    Text("Scan")
                                        .font(NBType.body)
                                }
                                .foregroundStyle(NBColors.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .background(NBColors.yellow)
                                .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                                .overlay(
                                    RoundedRectangle(cornerRadius: NBTheme.corner)
                                        .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, NBTheme.padding)
                        .padding(.bottom, 100) // Space for bottom tab bar
                    }
                }
            }
            .navigationDestination(isPresented: $showPages) {
                PagesView(sessionStore: sessionStore)
            }
            .navigationBarHidden(true)
            .onChange(of: selectedPhotoItems) { oldValue, newValue in
                Task {
                    await loadPhotos(from: newValue)
                }
            }
            .sheet(isPresented: $showDocumentScanner) {
                DocumentScannerView(isPresented: $showDocumentScanner) { images in
                    handleScannedDocuments(images)
                }
            }
        }
    }
    
    @MainActor
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        
        var loadedCount = 0
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                sessionStore.addPage(uiImage)
                loadedCount += 1
            }
        }
        
        // Navigate to PagesView after loading photos (if any were loaded)
        if loadedCount > 0 {
            showPages = true
        }
        
        // Clear selection so onChange can trigger again if user selects more photos
        selectedPhotoItems = []
    }
    
    @MainActor
    private func handleScannedDocuments(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        
        for image in images {
            sessionStore.addPage(image)
        }
        
        // Navigate to PagesView after adding scanned pages
        if !images.isEmpty {
            showPages = true
        }
    }
}

#Preview {
    ScanView()
}
