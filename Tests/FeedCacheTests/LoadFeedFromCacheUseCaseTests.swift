import FeedCache
import FeedFeature
import XCTest

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_init_whenCalled_shouldNotMessageStoreUponInitialisation() {
        let (_, store) = makeSut()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_whenCalled_shouldRequestCacheRetrieval() {
        let (sut, store) = makeSut()
        
        sut.load() { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenReceivesRetrievalError_shouldFail() {
        let (sut, store) = makeSut()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }
    
    func test_load_whenCacheIsEmpty_shouldDeliverEmptyMoviesPage() {
        let (sut, store) = makeSut()
        let emptyMoviesPage = MoviesPage(page: 1, results: [], totalResults: 1, totalPages: 1)
        
        expect(sut, toCompleteWith: .success(emptyMoviesPage), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }
    
    func test_load_whenCacheIsNonExpired_shouldDeliverCachedMoviesPage() {
        let moviesPage = uniqueMoviesPages()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(moviesPage.model), when: {
            store.completeRetrieval(with: moviesPage.cache, timestamp: nonExpiredTimestamp)
        })
    }
    
    func test_load_whenCacheHasReachedExpiration_shouldDeliverEmptyMoviesPage() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let emptyMoviesPage = emptyMoviesPages().model
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(emptyMoviesPage), when: {
            store.completeRetrieval(with: cachedMoviesPage, timestamp: expirationTimestamp)
        })
    }
    
    func test_load_whenCacheHasExceededExpiration_shouldDeliverEmptyMoviesPage() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let emptyMoviesPage = emptyMoviesPages().model
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(emptyMoviesPage), when: {
            store.completeRetrieval(with: cachedMoviesPage, timestamp: expiredTimestamp)
        })
    }
    
    func test_load_whenReceivesRetrievalError_shouldNotHaveSideEffects() {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenCacheIsEmpty_shouldNotHaveSideEffects() {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenCacheIsNonExpired_shouldNotHaveSideEffects() {
        let moviesPage = uniqueMoviesPages()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: moviesPage.cache, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenCacheHasReachedExpiration_shouldHaveNoSideEffects() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: cachedMoviesPage, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenCacheHasExceededExpiration_shouldHaveNoSideEffects() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: cachedMoviesPage, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenSutInstanceHasBeenDeallocated_shouldNotDeliverResult() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
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
    
    func expect(
        _ sut: LocalFeedLoader,
        toCompleteWith expectedResult: LocalFeedLoader.LoadResult,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for load() completion")

        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedMoviesPage), .success(expectedMoviesPage)):
                XCTAssertEqual(receivedMoviesPage, expectedMoviesPage, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            expectation.fulfill()
        }

        action()
        wait(for: [expectation], timeout: 1.0)
    }
}
