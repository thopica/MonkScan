import SwiftUI

// MARK: - Export Share Format
enum ExportShareFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case images = "Images"
    case text = "Text"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .pdf: return "doc.fill"
        case .images: return "photo.on.rectangle"
        case .text: return "doc.text"
        }
    }
}

// MARK: - Share Document Sheet
struct ShareDocumentSheet: View {
    @Binding var documentName: String
    @Binding var selectedFormat: ExportShareFormat
    let pages: [ScanPage]
    var allowNameEditing: Bool = true
    let onShare: (String, ExportShareFormat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                NBColors.paper.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Document name input
                    NBCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Document Name")
                                .font(NBType.body)
                                .foregroundStyle(NBColors.ink)
                            
                            if allowNameEditing {
                                NBTextField(placeholder: "Enter document name...", systemIcon: nil, text: $documentName)
                            } else {
                                Text(documentName)
                                    .font(NBType.regular)
                                    .foregroundStyle(NBColors.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(NBColors.warmCard.opacity(0.5))
                                    .overlay(RoundedRectangle(cornerRadius: NBTheme.corner)
                                        .stroke(NBColors.ink, lineWidth: NBTheme.stroke))
                                    .cornerRadius(NBTheme.corner)
                            }
                        }
                    }
                    .padding(.horizontal, NBTheme.padding)
                    
                    // Format selection and preview
                    NBCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Format")
                                .font(NBType.body)
                                .foregroundStyle(NBColors.ink)
                            
                            HStack(spacing: 10) {
                                ForEach(ExportShareFormat.allCases) { format in
                                    Button {
                                        selectedFormat = format
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: format.systemImage)
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(format.rawValue)
                                                .font(NBType.caption)
                                        }
                                        .foregroundStyle(NBColors.ink)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 10)
                                        .background(selectedFormat == format ? NBColors.yellow : NBColors.warmCard)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 999)
                                                .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                                        )
                                        .cornerRadius(999)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            Divider()
                                .background(NBColors.ink.opacity(0.2))
                            
                            Text("Preview")
                                .font(NBType.body)
                                .foregroundStyle(NBColors.ink)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(NBColors.warmCard)
                                                .frame(width: 60, height: 80)
                                            
                                            if let image = page.uiImage {
                                                let adjusted = ImageProcessingService.applyAdjustments(
                                                    to: image,
                                                    brightness: page.brightness,
                                                    contrast: page.contrast,
                                                    rotation: page.rotation
                                                )
                                                Image(uiImage: adjusted)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(NBColors.ink, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            Text("\(pages.count) page\(pages.count == 1 ? "" : "s")")
                                .font(NBType.caption)
                                .foregroundStyle(NBColors.mutedInk)
                        }
                    }
                    .padding(.horizontal, NBTheme.padding)
                    
                    Spacer()
                    
                    // Export button
                    Button {
                        onShare(documentName, selectedFormat)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                        .font(NBType.body)
                        .foregroundStyle(NBColors.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(NBColors.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                        .overlay(
                            RoundedRectangle(cornerRadius: NBTheme.corner)
                                .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(documentName.isEmpty)
                    .padding(.horizontal, NBTheme.padding)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

