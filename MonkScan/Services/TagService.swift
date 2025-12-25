import Foundation

// MARK: - Tag Categories and Predefined Tags
struct TagService {
    // Predefined common tags organized by category
    static let predefinedTags: [TagCategory] = [
        TagCategory(name: "Document Type", tags: [
            "Receipt", "Invoice", "Contract", "Letter", "Form", 
            "Report", "Certificate", "ID Document"
        ]),
        TagCategory(name: "Category", tags: [
            "Personal", "Business", "Tax", "Medical", "Legal",
            "Education", "Travel", "Insurance"
        ]),
        TagCategory(name: "Priority", tags: [
            "Important", "Urgent", "Archive", "Review"
        ]),
        TagCategory(name: "Year", tags: [
            "2024", "2023", "2022", "2021"
        ])
    ]
    
    // Get all tags flattened
    static var allPredefinedTags: [String] {
        predefinedTags.flatMap { $0.tags }
    }
    
    // Search tags
    static func searchTags(query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        return allPredefinedTags.filter { 
            $0.lowercased().contains(query.lowercased()) 
        }
    }
}

// MARK: - Tag Category
struct TagCategory: Identifiable {
    let id = UUID()
    let name: String
    let tags: [String]
}

