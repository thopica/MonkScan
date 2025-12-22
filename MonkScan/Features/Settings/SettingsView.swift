import SwiftUI

struct SettingsView: View {
    @State private var defaultFormat: ExportFormat = .pdf
    @State private var ocrLanguage: String = "English"
    @State private var autoNaming: Bool = true
    @State private var flashDefault: FlashSetting = .auto
    @State private var autoCapture: Bool = true
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case jpg = "JPG"
        case text = "Text"
    }
    
    enum FlashSetting: String, CaseIterable {
        case off = "Off"
        case on = "On"
        case auto = "Auto"
    }
    
    var body: some View {
        NBScreen {
            VStack(spacing: 14) {
                NBTopBar(title: "Settings")
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Export settings
                        NBCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Export")
                                    .font(NBType.header)
                                    .foregroundStyle(NBColors.ink)
                                
                                SettingsRow(title: "Default Format", value: defaultFormat.rawValue) {
                                    // Cycle through formats
                                    let all = ExportFormat.allCases
                                    if let idx = all.firstIndex(of: defaultFormat) {
                                        defaultFormat = all[(idx + 1) % all.count]
                                    }
                                }
                                
                                Divider().background(NBColors.ink.opacity(0.2))
                                
                                SettingsRow(title: "OCR Language", value: ocrLanguage) {
                                    // Would show picker
                                }
                            }
                        }
                        
                        // Scan settings
                        NBCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scanning")
                                    .font(NBType.header)
                                    .foregroundStyle(NBColors.ink)
                                
                                SettingsToggleRow(title: "Auto Filename", subtitle: "Generate name from date", isOn: $autoNaming)
                                
                                Divider().background(NBColors.ink.opacity(0.2))
                                
                                SettingsRow(title: "Flash Default", value: flashDefault.rawValue) {
                                    let all = FlashSetting.allCases
                                    if let idx = all.firstIndex(of: flashDefault) {
                                        flashDefault = all[(idx + 1) % all.count]
                                    }
                                }
                                
                                Divider().background(NBColors.ink.opacity(0.2))
                                
                                SettingsToggleRow(title: "Auto Capture", subtitle: "Capture when document detected", isOn: $autoCapture)
                            }
                        }
                        
                        // About
                        NBCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("About")
                                    .font(NBType.header)
                                    .foregroundStyle(NBColors.ink)
                                
                                HStack {
                                    Text("Version")
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.ink)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(NBType.body)
                                        .foregroundStyle(NBColors.mutedInk)
                                }
                                
                                Divider().background(NBColors.ink.opacity(0.2))
                                
                                Button {
                                    // Rate app
                                } label: {
                                    HStack {
                                        Text("Rate MonkScan")
                                            .font(NBType.body)
                                            .foregroundStyle(NBColors.ink)
                                        Spacer()
                                        Image(systemName: "star")
                                            .foregroundStyle(NBColors.yellow)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(NBType.body)
                    .foregroundStyle(NBColors.ink)
                Spacer()
                HStack(spacing: 6) {
                    Text(value)
                        .font(NBType.body)
                        .foregroundStyle(NBColors.mutedInk)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NBColors.mutedInk)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(NBType.body)
                    .foregroundStyle(NBColors.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(NBType.caption)
                        .foregroundStyle(NBColors.mutedInk)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(NBColors.yellow)
                .labelsHidden()
        }
    }
}

#Preview {
    SettingsView()
}
