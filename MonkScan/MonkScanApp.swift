import SwiftUI

@main
struct MonkScanApp: App {
    @StateObject private var libraryStore: LibraryStore
    
    init() {
        // Initialize document store and library store
        let documentStore = try! FileDocumentStore()
        _libraryStore = StateObject(wrappedValue: LibraryStore(documentStore: documentStore))
    }
    
    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(libraryStore)
                .task {
                    // Load documents on app launch
                    await libraryStore.loadDocuments()
                }
        }
    }
}
