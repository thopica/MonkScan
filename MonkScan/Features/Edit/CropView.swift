import SwiftUI

struct CropView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEnhance = false
    
    var body: some View {
        ZStack {
            NBColors.ink.ignoresSafeArea()
            
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
                    
                    Text("Crop")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.paper)
                    
                    Spacer()
                    
                    Button {
                        showEnhance = true
                    } label: {
                        Text("Next")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.yellow)
                    }
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                
                Spacer()
                
                // Image preview with crop corners
                ZStack {
                    // Placeholder image
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NBColors.mutedInk)
                        .frame(width: 280, height: 360)
                        .overlay(
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(NBColors.paper.opacity(0.3))
                        )
                    
                    // Crop frame with corner handles
                    CropFrameOverlay()
                        .frame(width: 280, height: 360)
                }
                
                Spacer()
                
                // Bottom controls
                HStack(spacing: 32) {
                    VStack(spacing: 6) {
                        NBIconButton(systemName: "rotate.left", filled: false, size: 50) {
                            // Rotate left
                        }
                        Text("Rotate")
                            .font(NBType.caption)
                            .foregroundStyle(NBColors.paper)
                    }
                    
                    VStack(spacing: 6) {
                        NBIconButton(systemName: "crop", filled: false, size: 50) {
                            // Auto crop
                        }
                        Text("Auto")
                            .font(NBType.caption)
                            .foregroundStyle(NBColors.paper)
                    }
                    
                    VStack(spacing: 6) {
                        NBIconButton(systemName: "arrow.up.left.and.arrow.down.right", filled: false, size: 50) {
                            // Manual adjust
                        }
                        Text("Manual")
                            .font(NBType.caption)
                            .foregroundStyle(NBColors.paper)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationDestination(isPresented: $showEnhance) {
            EnhanceView()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Crop Frame Overlay
struct CropFrameOverlay: View {
    var body: some View {
        ZStack {
            // Border
            Rectangle()
                .stroke(NBColors.yellow, lineWidth: 2)
            
            // Corner handles
            ForEach(Corner.allCases, id: \.self) { corner in
                CornerHandle()
                    .position(corner.position(in: CGSize(width: 280, height: 360)))
            }
        }
    }
    
    enum Corner: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
        
        func position(in size: CGSize) -> CGPoint {
            switch self {
            case .topLeft: return CGPoint(x: 0, y: 0)
            case .topRight: return CGPoint(x: size.width, y: 0)
            case .bottomLeft: return CGPoint(x: 0, y: size.height)
            case .bottomRight: return CGPoint(x: size.width, y: size.height)
            }
        }
    }
}

struct CornerHandle: View {
    var body: some View {
        Circle()
            .fill(NBColors.yellow)
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(NBColors.ink, lineWidth: 2))
    }
}

#Preview {
    NavigationStack {
        CropView()
    }
}

