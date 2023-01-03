import FeedFeature
import Foundation

public final class LocalFeedLoader {
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadMoviesPageResult
    
    // MARK: - Private Properties
    
    private let store: FeedStore
    private let currentDate: () -> Date
    private let calendar = Calendar(identifier: .gregorian)

    private var maxCacheAgeInDays = 7
    
    // MARK: - Init
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
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
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [unowned self] result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .found(moviesPage, timestamp) where validate(timestamp):
                completion(.success(moviesPage.toDomain()))
                
            case .found, .empty:
                let moviesPage = MoviesPage(page: 1, results: [], totalResults: 1, totalPages: 1)
                completion(.success(moviesPage))
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
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return currentDate() < maxCacheAge
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
