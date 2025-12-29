import SwiftUI

@main
struct MonkScanApp: App {
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var settingsStore: SettingsStore
    @State private var showWelcomeScreen = true
    
    init() {
        // Initialize document store and library store
        let documentStore: FileDocumentStore
        do {
            documentStore = try FileDocumentStore()
        } catch {
            // Log the error for debugging
            print("FATAL: Could not initialize document storage: \(error)")
            // For production, this is a critical failure - app cannot function without storage
            fatalError("Failed to create document directory. Please check device storage and permissions.")
        }
        _libraryStore = StateObject(wrappedValue: LibraryStore(documentStore: documentStore))
        _settingsStore = StateObject(wrappedValue: SettingsStore())
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppTabView()
                    .environmentObject(libraryStore)
                    .environmentObject(settingsStore)
                    .task {
                        // Load documents on app launch
                        await libraryStore.loadDocuments()
                    }
                
                if showWelcomeScreen {
                    WelcomeScreenView {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showWelcomeScreen = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
