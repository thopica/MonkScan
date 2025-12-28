import SwiftUI

@main
struct MonkScanApp: App {
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var settingsStore: SettingsStore
    
    init() {
        // Initialize document store and library store
        let documentStore = try! FileDocumentStore()
        _libraryStore = StateObject(wrappedValue: LibraryStore(documentStore: documentStore))
        _settingsStore = StateObject(wrappedValue: SettingsStore())
    }
    
    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(libraryStore)
                .environmentObject(settingsStore)
                .task {
                    // Load documents on app launch
                    await libraryStore.loadDocuments()
                }
        }
    }
}
