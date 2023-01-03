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
