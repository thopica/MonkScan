import SwiftUI
import Combine

// MARK: - Tab Coordinator
class TabCoordinator: ObservableObject {
    @Published var selectedTab: AppTabView.Tab = .library
    
    func switchTo(_ tab: AppTabView.Tab) {
        selectedTab = tab
    }
}

