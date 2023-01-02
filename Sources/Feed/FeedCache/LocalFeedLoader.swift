import Foundation

public final class LocalFeedLoader {
    
    public typealias SaveResult = Error?
    
    // MARK: - Private Properties
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    // MARK: - Init
    
    public init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
    
    // MARK: - API
    
    public func save(_ moviesPage: MoviesPage, completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed() { [weak self] error in
            guard let self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(moviesPage, with: completion)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func cache(_ moviesPage: MoviesPage, with completion: @escaping (SaveResult) -> Void) {
        store.insert(moviesPage.toCacheMoviesPage(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
}

private extension MoviesPage {
    func toCacheMoviesPage() -> CacheMoviesPage {
        CacheMoviesPage(
            page: self.page,
            results: self.results.toCacheMovie(),
            totalResults: self.totalResults,
            totalPages: self.totalPages
        )
    }
}

private extension Array where Element == Movie {
    func toCacheMovie() -> [CacheMovie] {
        return map { CacheMovie(id: $0.id, title: $0.title) }
    }
}
