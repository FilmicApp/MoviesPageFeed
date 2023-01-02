import Feed
import XCTest

class LocalFeedLoader {
    
    // MARK: - Private Properties
    
    private let store: FeedStore
    
    // MARK: - Init
    
    init(store: FeedStore) {
        self.store = store
    }
    
    // MARK: - API
    
    func save(_ moviesPage: MoviesPage) {
        store.deleteCachedFeed() { [unowned self] error in
            if error == nil {
                self.store.insert(moviesPage)
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ moviesPage: MoviesPage) {
        insertCallCount += 1
    }
}

class CacheFeedUseCase: XCTestCase {
    
    func test_init_whenCalled_shouldNotDeleteCacheUponInitialisation() {
        let (_, store) = makeSut()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_whenCalled_shouldRequestCacheDeletion() {
        let (sut, store) = makeSut()
        
        sut.save(uniqueMoviesPage())
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_whenReceivesDeletionError_shouldNotRequestCacheInsertion() {
        let moviesPage = uniqueMoviesPage()
        let (sut, store) = makeSut()
        let deletionError = anyNSError()
        
        sut.save(moviesPage)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_whenCacheDeletionIsSuccessful_shouldRequestNewCacheInsertion() {
        let moviesPage = uniqueMoviesPage()
        let (sut, store) = makeSut()
        
        sut.save(moviesPage)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSut() -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        trackForMemoryLeaks(store)
        trackForMemoryLeaks(sut)

        return (sut, store)
    }

    private func uniqueMoviesPage() -> MoviesPage {
        let totalPages: Int = .random(in: 1...5)
        let currentPage: Int = .random(in: 1...totalPages)
        
        return MoviesPage(
            page: currentPage,
            results: [uniqueMovie()],
            totalResults: .random(in: 6...10),
            totalPages: totalPages
        )
    }
    
    private func uniqueMovie() -> Movie {
        Movie(
            id: .random(in: 100000...200000),
            title: "AnyTitle"
        )
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
}
