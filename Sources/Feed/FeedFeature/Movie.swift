public struct MoviesPage: Codable, Equatable {
    let page: Int
    let results: [Movie]
    let totalResults: Int
    let totalPages: Int
    
    public init(page: Int, results: [Movie], totalResults: Int, totalPages: Int) {
        self.page = page
        self.results = results
        self.totalResults = totalResults
        self.totalPages = totalPages
    }
}

public struct Movie: Codable, Equatable {
    let id: Int
    let title: String
}

