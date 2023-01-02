import Feed
import XCTest

class LocalFeedLoader {
    
    // MARK: - Private Properties
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    // MARK: - Init
    
    init(store: FeedStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
    
    // MARK: - API
    
    func save(_ moviesPage: MoviesPage) {
        store.deleteCachedFeed() { [unowned self] error in
            if error == nil {
                self.store.insert(moviesPage, timestamp: self.currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    var deleteCachedFeedCallCount = 0
    var insertions = [(moviesPage: MoviesPage, timestamp: Date)]()
    
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
    
    func insert(_ moviesPage: MoviesPage, timestamp: Date) {
        insertions.append((moviesPage, timestamp))
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
        
        XCTAssertEqual(store.insertions.count, 0)
    }
        
    func test_save_whenCacheDeletionIsSuccessful_shouldRequestNewCacheInsertionWithTimestamp() {
        let timestamp = Date()
        let moviesPage = uniqueMoviesPage()
        let (sut, store) = makeSut(currentDate: { timestamp })
        
        sut.save(moviesPage)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.moviesPage, moviesPage)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }
    
    // MARK: - Helpers
    
    private func makeSut(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
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
