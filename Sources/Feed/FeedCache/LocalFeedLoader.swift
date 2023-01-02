import Foundation

public final class LocalFeedLoader {
    
    // MARK: - Private Properties
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    // MARK: - Init
    
    public init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
    
    // MARK: - API
    
    public func save(_ moviesPage: MoviesPage, completion: @escaping (Error?) -> Void) {
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
    
    private func cache(_ moviesPage: MoviesPage, with completion: @escaping (Error?) -> Void) {
        store.insert(moviesPage, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
}
