import Foundation

struct ScanFolder: Identifiable {
    let id = UUID()
    var name: String
    var count: Int
}

struct ScanDoc: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var stars: Int
}
