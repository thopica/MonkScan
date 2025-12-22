import Foundation
import SwiftUI
import PhotosUI

// MARK: - PhotoImportService Protocol
protocol PhotoImportService {
    func importPhoto() async throws -> UIImage?
}

// MARK: - RealPhotoImportService
@MainActor
class RealPhotoImportService: PhotoImportService {
    func importPhoto() async throws -> UIImage? {
        // This will be called from SwiftUI PhotosPicker
        // The actual implementation is handled by PhotosPicker in the view
        return nil
    }
}

// MARK: - PhotosPicker Helper
struct PhotoPickerHelper {
    @Binding var selectedItem: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void
    
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            await MainActor.run {
                onImageSelected(uiImage)
            }
        }
    }
}

