public struct CacheMoviesPage: Equatable {
    
    // MARK: - Public Properties
    
    public let page: Int
    public let results: [CacheMovie]
    public let totalResults: Int
    public let totalPages: Int
    
    // MARK: - Init
    
    public init(page: Int, results: [CacheMovie], totalResults: Int, totalPages: Int) {
        self.page = page
        self.results = results
        self.totalResults = totalResults
        self.totalPages = totalPages
    }
}

