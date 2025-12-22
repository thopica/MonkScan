import SwiftUI

struct AppTabView: View {
    @State private var selectedTab: Tab = .library
    
    enum Tab {
        case library
        case scan
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "doc.text")
                }
                .tag(Tab.library)
            
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }
                .tag(Tab.scan)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(NBColors.ink)
    }
}

#Preview {
    AppTabView()
}

