import SwiftUI
import PhotosUI
import VisionKit
import AVFoundation
import UIKit

struct ScanView: View {
    @StateObject private var sessionStore = ScanSessionStore()
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var showPages = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showDocumentScanner = false
    
    @State private var activeAlert: ActiveAlert?
    @State private var showAlert = false
    
    private struct ActiveAlert {
        let title: String
        let message: String
        let showsSettingsButton: Bool
    }
    
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
                                Task { await startScanTapped() }
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
                } onScanError: { error in
                    showScanFailedAlert(error)
                }
            }
            .alert(activeAlert?.title ?? "", isPresented: $showAlert) {
                if activeAlert?.showsSettingsButton == true {
                    Button("Open Settings") {
                        openAppSettings()
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(activeAlert?.message ?? "")
            }
            .onAppear {
                sessionStore.setAutoNamingEnabled(settingsStore.autoNaming)
            }
            .onChange(of: settingsStore.autoNaming) { _, newValue in
                sessionStore.setAutoNamingEnabled(newValue)
            }
        }
    }
    
    @MainActor
    private func startScanTapped() async {
        guard VNDocumentCameraViewController.isSupported else {
            presentAlert(
                title: "Scanning Not Supported",
                message: "Document scanning isn’t available on this device. Try on a physical iPhone/iPad.",
                showsSettingsButton: false
            )
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showDocumentScanner = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                showDocumentScanner = true
            } else {
                presentAlert(
                    title: "Camera Access Needed",
                    message: "Allow camera access to scan documents.",
                    showsSettingsButton: true
                )
            }
        case .denied, .restricted:
            presentAlert(
                title: "Camera Access Needed",
                message: "Camera access is turned off for MonkScan. You can enable it in Settings.",
                showsSettingsButton: true
            )
        @unknown default:
            presentAlert(
                title: "Camera Unavailable",
                message: "We couldn’t access the camera right now. Please try again.",
                showsSettingsButton: false
            )
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
        } else {
            presentAlert(
                title: "Couldn’t Import Photos",
                message: "No images were imported. Please check Photos access for MonkScan in Settings and try again.",
                showsSettingsButton: true
            )
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
    
    @MainActor
    private func showScanFailedAlert(_ error: Error) {
        presentAlert(
            title: "Scan Failed",
            message: error.localizedDescription,
            showsSettingsButton: false
        )
    }
    
    @MainActor
    private func presentAlert(title: String, message: String, showsSettingsButton: Bool) {
        activeAlert = ActiveAlert(title: title, message: message, showsSettingsButton: showsSettingsButton)
        showAlert = true
    }
    
    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ScanView()
}
