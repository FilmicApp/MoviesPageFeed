public struct MoviesPage: Equatable {
    
    // MARK: - Public Properties
    
    public let page: Int
    public let results: [Movie]
    public let totalResults: Int
    public let totalPages: Int
    
    // MARK: - Init
    
    public init(page: Int, results: [Movie], totalResults: Int, totalPages: Int) {
        self.page = page
        self.results = results
        self.totalResults = totalResults
        self.totalPages = totalPages
    }
}

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

