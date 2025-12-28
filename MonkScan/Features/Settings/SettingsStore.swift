import Foundation
import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    enum ExportFormat: String, CaseIterable, Codable {
        case pdf = "PDF"
        case jpg = "JPG"
        case text = "Text"
    }
    
    enum FlashSetting: String, CaseIterable, Codable {
        case off = "Off"
        case on = "On"
        case auto = "Auto"
    }
    
    private enum Keys {
        static let defaultExportFormat = "settings.defaultExportFormat"
        static let autoNaming = "settings.autoNaming"
        static let flashDefault = "settings.flashDefault"
        static let autoCapture = "settings.autoCapture"
    }
    
    private let defaults: UserDefaults
    
    @Published var defaultExportFormat: ExportFormat {
        didSet { defaults.set(defaultExportFormat.rawValue, forKey: Keys.defaultExportFormat) }
    }
    
    @Published var autoNaming: Bool {
        didSet { defaults.set(autoNaming, forKey: Keys.autoNaming) }
    }
    
    @Published var flashDefault: FlashSetting {
        didSet { defaults.set(flashDefault.rawValue, forKey: Keys.flashDefault) }
    }
    
    @Published var autoCapture: Bool {
        didSet { defaults.set(autoCapture, forKey: Keys.autoCapture) }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        
        let defaultExportFormatRaw = defaults.string(forKey: Keys.defaultExportFormat) ?? ExportFormat.pdf.rawValue
        self.defaultExportFormat = ExportFormat(rawValue: defaultExportFormatRaw) ?? .pdf
        
        if defaults.object(forKey: Keys.autoNaming) == nil {
            self.autoNaming = true
        } else {
            self.autoNaming = defaults.bool(forKey: Keys.autoNaming)
        }
        
        let flashDefaultRaw = defaults.string(forKey: Keys.flashDefault) ?? FlashSetting.auto.rawValue
        self.flashDefault = FlashSetting(rawValue: flashDefaultRaw) ?? .auto
        
        if defaults.object(forKey: Keys.autoCapture) == nil {
            self.autoCapture = true
        } else {
            self.autoCapture = defaults.bool(forKey: Keys.autoCapture)
        }
    }
}


