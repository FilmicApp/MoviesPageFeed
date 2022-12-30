public struct Movie: Equatable {
    
    // MARK: - Public Properties
    
    public let id: Int
    public let title: String
    
    // MARK: - Init
    
    public init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}
