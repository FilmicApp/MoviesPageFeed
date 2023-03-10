import FeedFeature
import Foundation

public final class LocalFeedLoader {
    
    // MARK: - Private Properties
    
    private let store: FeedStore
    private let currentDate: () -> Date
        
    // MARK: - Init
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader {
    
    public typealias SaveResult = Error?

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

extension LocalFeedLoader: MoviesPageLoader {
    
    public typealias LoadResult = LoadMoviesPageResult

    // MARK: - API
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .found(moviesPage, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(moviesPage.toDomain()))
                
            case .found, .empty:
                let moviesPage = MoviesPage(page: 1, results: [], totalResults: 1, totalPages: 1)
                completion(.success(moviesPage))
            }
        }
    }
}

extension LocalFeedLoader {
    
    // MARK: - API
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .failure(_):
                self.store.deleteCachedFeed { _ in }
                
            case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCachedFeed { _ in }
                
            case .empty, .found:
                break
            }
        }
    }
}

private extension MoviesPage {
    func toCacheMoviesPage() -> CacheMoviesPage {
        CacheMoviesPage(
            page: self.page,
            results: self.results.toCacheMovies(),
            totalResults: self.totalResults,
            totalPages: self.totalPages
        )
    }
}

private extension Array where Element == Movie {
    func toCacheMovies() -> [CacheMovie] {
        return map { CacheMovie(id: $0.id, title: $0.title) }
    }
}

private extension CacheMoviesPage {
    func toDomain() -> MoviesPage {
        MoviesPage(
            page: self.page,
            results: self.results.toDomain(),
            totalResults: self.totalResults,
            totalPages: self.totalPages
        )
    }
}

private extension Array where Element == CacheMovie {
    func toDomain() -> [Movie] {
        return map { Movie(id: $0.id, title: $0.title) }
    }
}
