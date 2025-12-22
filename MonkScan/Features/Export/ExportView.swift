import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var documentTitle = "Scan 2024-12-20"
    @State private var showDoneAlert = false
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case jpg = "JPG"
        case text = "Text"
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .jpg: return "photo"
            case .text: return "doc.text"
            }
        }
    }
    
    var body: some View {
        NBScreen {
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
                        .foregroundStyle(NBColors.ink)
                    }
                    
                    Spacer()
                    
                    Text("Export")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.ink)
                    
                    Spacer()
                    
                    // Invisible placeholder for centering
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .opacity(0)
                }
                .padding(.top, 10)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Document title
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Document Name")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                NBTextField(placeholder: "Enter title...", text: $documentTitle)
                            }
                        }
                        
                        // Format selection
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Export Format")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                HStack(spacing: 12) {
                                    ForEach(ExportFormat.allCases, id: \.self) { format in
                                        FormatButton(
                                            format: format,
                                            isSelected: selectedFormat == format
                                        ) {
                                            selectedFormat = format
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Preview
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Preview")
                                    .font(NBType.body)
                                    .foregroundStyle(NBColors.ink)
                                
                                HStack(spacing: 12) {
                                    ForEach(1...3, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(NBColors.paper)
                                            .aspectRatio(0.75, contentMode: .fit)
                                            .overlay(
                                                Text("\(i)")
                                                    .font(NBType.caption)
                                                    .foregroundStyle(NBColors.mutedInk)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(NBColors.ink, lineWidth: 1)
                                            )
                                    }
                                    Spacer()
                                }
                                .frame(height: 80)
                                
                                Text("3 pages • \(selectedFormat.rawValue)")
                                    .font(NBType.caption)
                                    .foregroundStyle(NBColors.mutedInk)
                            }
                        }
                        
                        // OCR text preview (for Text export)
                        if selectedFormat == .text {
                            NBCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("OCR Text")
                                            .font(NBType.body)
                                            .foregroundStyle(NBColors.ink)
                                        Spacer()
                                        NBChip(text: "Preview", filled: false)
                                    }
                                    
                                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua...")
                                        .font(NBType.regular)
                                        .foregroundStyle(NBColors.mutedInk)
                                        .lineLimit(4)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 20)
                        
                        // Export buttons
                        VStack(spacing: 12) {
                            // Share button
                            Button {
                                showDoneAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
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
                            
                            // Save to Files button
                            Button {
                                showDoneAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("Save to Files")
                                }
                                .font(NBType.body)
                                .foregroundStyle(NBColors.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(NBColors.warmCard)
                                .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
                                .overlay(
                                    RoundedRectangle(cornerRadius: NBTheme.corner)
                                        .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Exported!", isPresented: $showDoneAlert) {
            Button("Done") {
                // In A3+ this will save to store and navigate to Library
            }
        } message: {
            Text("Your document has been exported successfully.")
        }
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let format: ExportView.ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: format.icon)
                    .font(.system(size: 24))
                Text(format.rawValue)
                    .font(NBType.caption)
            }
            .foregroundStyle(NBColors.ink)
            .frame(width: 70, height: 70)
            .background(isSelected ? NBColors.yellow : NBColors.warmCard)
            .clipShape(RoundedRectangle(cornerRadius: NBTheme.corner))
            .overlay(
                RoundedRectangle(cornerRadius: NBTheme.corner)
                    .stroke(NBColors.ink, lineWidth: NBTheme.stroke)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExportView()
    }
}

