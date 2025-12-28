import Foundation
import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    enum ExportFormat: String, CaseIterable, Codable {
        case pdf = "PDF"
        case jpg = "JPG"
        case text = "Text"
    }
    
    private enum Keys {
        static let defaultExportFormat = "settings.defaultExportFormat"
        static let autoNaming = "settings.autoNaming"
    }
    
    private let defaults: UserDefaults
    
    @Published var defaultExportFormat: ExportFormat {
        didSet { defaults.set(defaultExportFormat.rawValue, forKey: Keys.defaultExportFormat) }
    }
    
    @Published var autoNaming: Bool {
        didSet { defaults.set(autoNaming, forKey: Keys.autoNaming) }
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
        
    }
}

// MARK: - Helpers
extension SettingsStore.ExportFormat {
    var exportShareFormat: ExportShareFormat {
        switch self {
        case .pdf: return .pdf
        case .jpg: return .images
        case .text: return .text
        }
    }
}


