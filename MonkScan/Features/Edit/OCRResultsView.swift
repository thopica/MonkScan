import SwiftUI
import UniformTypeIdentifiers

struct OCRResultsView: View {
    let ocrText: String
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showCopiedAlert = false
    
    @State private var shareItems: [Any] = []
    @State private var showExportErrorAlert = false
    @State private var exportErrorMessage = ""
    
    var body: some View {
        ZStack {
            NBColors.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(NBColors.ink)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("OCR Results")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.ink)
                    
                    Spacer()
                    
                    // Invisible placeholder for centering
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                        .opacity(0)
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                
                // Text content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        NBCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Recognized Text")
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.ink)
                                    Spacer()
                                    Text("\(ocrText.count) characters")
                                        .font(NBType.caption)
                                        .foregroundStyle(NBColors.mutedInk)
                                }
                                
                                Divider()
                                    .background(NBColors.ink.opacity(0.2))
                                
                                Text(ocrText)
                                    .font(NBType.regular)
                                    .foregroundStyle(NBColors.ink)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.bottom, 120) // Space for bottom toolbar
                }
                
                Spacer()
            }
            
            // Bottom toolbar
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    // Copy button
                    Button {
                        copyToClipboard()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
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
                    
                    // Export button
                    Button {
                        if let url = createTextFile() {
                            shareItems = [url]
                            showShareSheet = true
                        } else {
                            exportErrorMessage = "Couldn’t create the text file. Please try again."
                            showExportErrorAlert = true
                        }
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
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 16)
                .background(NBColors.paper)
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: -4)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
        }
        .alert("Export Failed", isPresented: $showExportErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Text has been copied to clipboard")
        }
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        UIPasteboard.general.string = ocrText
        showCopiedAlert = true
    }
    
    private func createTextFile() -> URL? {
        let fileName = "OCR-\(Date().timeIntervalSince1970).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try ocrText.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            return nil
        }
        
        return tempURL
    }
}

// MARK: - Share Sheet (UIActivityViewController wrapper)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    OCRResultsView(ocrText: """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit.
        Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
        nisi ut aliquip ex ea commodo consequat.
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse
        cillum dolore eu fugiat nulla pariatur.
        """)
}

