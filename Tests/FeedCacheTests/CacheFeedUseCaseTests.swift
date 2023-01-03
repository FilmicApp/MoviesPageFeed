import FeedCache
import FeedFeature
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
        let moviesPage = uniqueMoviesPages()
        let (sut, store) = makeSut(currentDate: { timestamp })
        
        sut.save(moviesPage.model)  { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(moviesPage.cache, timestamp)])
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
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
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
