import SwiftUI

struct EnhanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPages = false
    @State private var selectedPreset: FilterPreset = .auto
    @State private var enhanceValue: Double = 0.5
    
    enum FilterPreset: String, CaseIterable {
        case auto = "Auto"
        case color = "Color"
        case gray = "Gray"
        case bw = "B&W"
    }
    
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
                    
                    Text("Enhance")
                        .font(NBType.header)
                        .foregroundStyle(NBColors.paper)
                    
                    Spacer()
                    
                    Button {
                        showPages = true
                    } label: {
                        Text("Next")
                            .font(NBType.body)
                            .foregroundStyle(NBColors.yellow)
                    }
                }
                .padding(.horizontal, NBTheme.padding)
                .padding(.vertical, 12)
                
                Spacer()
                
                // Image preview
                RoundedRectangle(cornerRadius: 4)
                    .fill(NBColors.mutedInk)
                    .frame(width: 280, height: 360)
                    .overlay(
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(NBColors.paper.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(NBColors.yellow, lineWidth: 2)
                    )
                
                Spacer()
                
                // Filter presets
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        ForEach(FilterPreset.allCases, id: \.self) { preset in
                            FilterPresetButton(
                                title: preset.rawValue,
                                isSelected: selectedPreset == preset
                            ) {
                                selectedPreset = preset
                            }
                        }
                    }
                    
                    // Enhance slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("Enhance")
                                .font(NBType.body)
                                .foregroundStyle(NBColors.paper)
                            Spacer()
                            Text("\(Int(enhanceValue * 100))%")
                                .font(NBType.caption)
                                .foregroundStyle(NBColors.yellow)
                        }
                        
                        Slider(value: $enhanceValue, in: 0...1)
                            .tint(NBColors.yellow)
                    }
                    .padding(.horizontal, NBTheme.padding)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        // Note: EnhanceView is no longer part of the main flow (ScanView → PagesView → ExportView)
        // Navigation to PagesView removed - this view is kept for potential future use
    }
}

struct FilterPresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? NBColors.yellow : NBColors.mutedInk)
                    .frame(width: 60, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? NBColors.ink : NBColors.paper.opacity(0.3), lineWidth: 2)
                    )
                
                Text(title)
                    .font(NBType.caption)
                    .foregroundStyle(isSelected ? NBColors.yellow : NBColors.paper)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        EnhanceView()
    }
}

