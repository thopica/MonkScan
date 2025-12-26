import SwiftUI

struct AppTabView: View {
    @StateObject private var tabCoordinator = TabCoordinator()
    
    enum Tab {
        case library
        case scan
        case settings
    }
    
    var body: some View {
        TabView(selection: $tabCoordinator.selectedTab) {
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
        .environmentObject(tabCoordinator)
    }
}

#Preview {
    AppTabView()
}

