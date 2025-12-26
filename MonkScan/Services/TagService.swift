import Foundation

// MARK: - Custom Tag Service with Persistence
class TagService {
    private static let userDefaultsKey = "monkscan.custom.tags"
    private static let hasInitializedKey = "monkscan.tags.initialized"
    
    // Default common tags to initialize on first launch
    private static let defaultTags = [
        "Receipt", "Invoice", "Contract", "Letter", "Form",
        "Personal", "Business", "Tax", "Medical", "Legal",
        "Education", "Travel", "Insurance", "Important"
    ]
    
    // MARK: - Load all saved custom tags
    static func loadTags() -> [String] {
        // Initialize default tags on first launch
        initializeDefaultTagsIfNeeded()
        
        if let savedTags = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            return savedTags.sorted()
        }
        return []
    }
    
    // MARK: - Initialize default tags on first launch
    private static func initializeDefaultTagsIfNeeded() {
        let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)
        if !hasInitialized {
            saveTags(defaultTags.sorted())
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
        }
    }
    
    // MARK: - Add a new custom tag
    static func addTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        var tags = loadTags()
        // Only add if not already exists (case-insensitive check)
        if !tags.contains(where: { $0.lowercased() == trimmedTag.lowercased() }) {
            tags.append(trimmedTag)
            saveTags(tags.sorted())
        }
    }
    
    // MARK: - Delete a tag globally
    static func deleteTag(_ tag: String) {
        var tags = loadTags()
        tags.removeAll { $0 == tag }
        saveTags(tags)
    }
    
    // MARK: - Save tags to UserDefaults
    private static func saveTags(_ tags: [String]) {
        UserDefaults.standard.set(tags, forKey: userDefaultsKey)
    }
    
    // MARK: - Search tags
    static func searchTags(query: String) -> [String] {
        guard !query.isEmpty else { return loadTags() }
        return loadTags().filter { 
            $0.lowercased().contains(query.lowercased()) 
        }
    }
}

