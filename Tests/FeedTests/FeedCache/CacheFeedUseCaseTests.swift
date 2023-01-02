import Feed
import XCTest

class CacheFeedUseCaseTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_init_whenCalled_shouldNotMessageStoreUponInitialisation() {
        let (_, store) = makeSut()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_whenCalled_shouldRequestCacheDeletion() {
        let (sut, store) = makeSut()
        
        sut.save(uniqueMoviesPage()) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_whenReceivesDeletionError_shouldNotRequestCacheInsertion() {
        let moviesPage = uniqueMoviesPage()
        let (sut, store) = makeSut()
        let deletionError = anyNSError()
        
        sut.save(moviesPage)  { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
        
    func test_save_whenCacheDeletionIsSuccessful_shouldRequestNewCacheInsertionWithTimestamp() {
        let timestamp = Date()
        let moviesPage = uniqueMoviesPage()
        let cacheMoviesPage = CacheMoviesPage(from: moviesPage)
        let (sut, store) = makeSut(currentDate: { timestamp })
        
        sut.save(moviesPage)  { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(cacheMoviesPage, timestamp)])
    }
    
    func test_save_whenReceivesDeletionError_shouldFail() {
        let (sut, store) = makeSut()
        let deletionError = anyNSError()
        
        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    func test_save_whenReceivesInsertionError_shouldFail() {
        let (sut, store) = makeSut()
        let insertionError = anyNSError()
        
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }
    
    func test_save_whenCacheInsertionIsSuccessful_shouldSucceed() {
        let (sut, store) = makeSut()
        
        expect(sut, toCompleteWithError: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }
    
    func test_save_whenSutInstanceHasBeenDeallocated_shouldNotDeliverDeletionError() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueMoviesPage()) { receivedResults.append($0) }
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_save_whenSutInstanceHasBeenDeallocated_shouldNotDeliverInsertionError() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueMoviesPage()) { receivedResults.append($0) }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    // MARK: - Factory methods
    
    private func makeSut(
        currentDate: @escaping () -> Date = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
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
    
    // MARK: - Helpers
    
    private func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithError expectedError: NSError?,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for save() completion")
        
        var receivedError: Error?
        sut.save(uniqueMoviesPage()) { error in
            receivedError = error
            expectation.fulfill()
        }
        
        action()
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError)
    }
}

extension CacheFeedUseCaseTests {
    private class FeedStoreSpy: FeedStore {
        
        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert(CacheMoviesPage, Date)
        }
        
        // MARK: - Private Properties
        
        private(set) var receivedMessages = [ReceivedMessage]()
        
        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        
        // MARK: - FeedStore API
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }
        
        func insert(_ moviesPage: CacheMoviesPage, timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(moviesPage, timestamp))
        }
        
        // MARK: - Spy Methods
                
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}

private extension CacheMoviesPage {
    init(from moviesPage: MoviesPage) {
        self.init(
            page: moviesPage.page,
            results: moviesPage.results.map { CacheMovie.init(from: $0) },
            totalResults: moviesPage.totalResults,
            totalPages: moviesPage.totalPages
        )
    }
}

private extension CacheMovie {
    init(from movie: Movie) {
        self.init(
            id: movie.id,
            title: movie.title
        )
    }
}
