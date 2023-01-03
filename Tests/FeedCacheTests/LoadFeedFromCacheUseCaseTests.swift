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
        let expectation = expectation(description: "Wait for load() completion")
        
        var receivedError: Error?
        sut.load() { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            expectation.fulfill()
        }
        
        store.completeRetrieval(with: retrievalError)
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, retrievalError)
    }
    
    func test_load_whenCacheIsEmpty_shouldDeliverNoMoviesPage() {
        let (sut, store) = makeSut()
        let expectation = expectation(description: "Wait for load() completion")

        var receivedMoviesPage: MoviesPage?
        sut.load() { result in
            switch result {
            case let .success(moviesPage):
                receivedMoviesPage = moviesPage
            default:
                XCTFail("Expected success, got \(result) instead")
            }
            expectation.fulfill()
        }

        store.completeRetrievalWithEmptyCache()
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedMoviesPage?.results, [])
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
    
    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }
}
