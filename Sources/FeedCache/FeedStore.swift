import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func insert(_ moviesPage: CacheMoviesPage, timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve()
}

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

public struct CacheMovie: Equatable {
    
    // MARK: - Public Properties
    
    public let id: Int
    public let title: String
    
    // MARK: - Init
    
    public init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}
