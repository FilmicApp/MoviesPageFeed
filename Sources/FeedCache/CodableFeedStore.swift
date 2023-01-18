import Foundation

public class CodableFeedStore: FeedStore {
    
    // MARK: - Private Properties
    
    private let storeURL: URL
    
    // MARK: - Init
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    // MARK: - API
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }
        
        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    public func insert(_ moviesPage: CacheMoviesPage, timestamp: Date, completion: @escaping InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let codableMoviesPage = CodableMoviesPage(moviesPage)
            let cache = Cache(moviesPage: codableMoviesPage, timestamp: timestamp)
            let encodedValues = try encoder.encode(cache)
            try encodedValues.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let codableCache = try decoder.decode(Cache.self, from: data)
            let cacheMoviesPage = codableCache.moviesPage.toCacheMoviesPage()
            completion(.found(moviesPage: cacheMoviesPage, timestamp: codableCache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
}

extension CodableFeedStore {
    private struct Cache: Codable {
        let moviesPage: CodableMoviesPage
        let timestamp: Date
    }
    
    private struct CodableMoviesPage: Codable {
        
        // MARK: - Private Properties
        
        private let page: Int
        private let results: [CodableMovie]
        private let totalResults: Int
        private let totalPages: Int
        
        // MARK: - Init
        
        init(_ moviesPage: CacheMoviesPage) {
            self.page = moviesPage.page
            self.results = moviesPage.results.map { CodableMovie($0) }
            self.totalResults = moviesPage.totalResults
            self.totalPages = moviesPage.totalPages
        }
        
        // MARK: - API
        
        func toCacheMoviesPage() -> CacheMoviesPage {
            CacheMoviesPage(
                page: self.page,
                results: self.results.map { $0.toCacheMovie() },
                totalResults: self.totalResults,
                totalPages: self.totalPages
            )
        }
    }
    
    private struct CodableMovie: Codable {
        
        // MARK: - Private Properties
        
        private let id: Int
        private let title: String
        
        // MARK: - Init
        
        init(_ movie: CacheMovie) {
            self.id = movie.id
            self.title = movie.title
        }
        
        // MARK: - API
        
        func toCacheMovie() -> CacheMovie {
            CacheMovie(
                id: self.id,
                title: self.title
            )
        }
    }
}
