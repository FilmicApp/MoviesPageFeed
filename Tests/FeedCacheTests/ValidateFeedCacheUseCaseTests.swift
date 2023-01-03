import FeedCache
import FeedFeature
import XCTest

class ValidateFeedCacheUseCaseTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_init_whenCalled_shouldNotMessageStoreUponInitialisation() {
        let (_, store) = makeSut()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_whenReceivesRetrievalError_shouldDeleteCache() {
        let (sut, store) = makeSut()
        
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_whenCacheIsEmpty_shouldNotDeleteCache() {
        let (sut, store) = makeSut()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_whenCacheIsNonExpired_shouldNotDeleteCache() {
        let moviesPage = uniqueMoviesPages()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: moviesPage.cache, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_whenCacheHasReachedExpiration_shouldDeleteCache() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: cachedMoviesPage, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_whenCacheHasExceededExpiration_shouldDeleteCache() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: cachedMoviesPage, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_whenSutInstanceHasBeenDeallocated_shouldNotDeleteInvalidCache() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()
        
        sut = nil
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
}
