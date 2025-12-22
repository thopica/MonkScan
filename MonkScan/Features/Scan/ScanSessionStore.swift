import Foundation
import SwiftUI
import Combine

@MainActor
class ScanSessionStore: ObservableObject {
    @Published var currentSession: ScanSession?
    
    func startNewSession() {
        currentSession = ScanSession()
    }
    
    func addPage(_ image: UIImage) {
        if currentSession == nil {
            startNewSession()
        }
        let page = ScanPage(uiImage: image)
        currentSession?.pages.append(page)
    }
    
    func removePage(at index: Int) {
        guard var session = currentSession,
              index >= 0 && index < session.pages.count else { return }
        session.pages.remove(at: index)
        currentSession = session
    }
    
    func rotatePage(at index: Int) {
        guard var session = currentSession,
              index >= 0 && index < session.pages.count else { return }
        session.pages[index].rotation = (session.pages[index].rotation + 90) % 360
        currentSession = session
    }
    
    func reorderPages(from source: IndexSet, to destination: Int) {
        guard var session = currentSession else { return }
        session.pages.move(fromOffsets: source, toOffset: destination)
        currentSession = session
    }
    
    func clearSession() {
        currentSession = nil
    }
}

