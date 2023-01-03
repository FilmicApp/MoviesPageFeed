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
    
    func test_load_whenCacheIsLessThanSevenDaysOld_shouldDeliverCachedMoviesPage() {
        let moviesPage = uniqueMoviesPages()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(moviesPage.model), when: {
            store.completeRetrieval(with: moviesPage.cache, timestamp: lessThanSevenDaysOldTimeStamp)
        })
    }
    
    func test_load_whenCacheIsSevenDaysOld_shouldDeliverEmptyMoviesPage() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let emptyMoviesPage = emptyMoviesPages().model
        let fixedCurrentDate = Date()
        let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(emptyMoviesPage), when: {
            store.completeRetrieval(with: cachedMoviesPage, timestamp: sevenDaysOldTimeStamp)
        })
    }
    
    func test_load_whenCacheIsMoreThanSevenDaysOld_shouldDeliverEmptyMoviesPage() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let emptyMoviesPage = emptyMoviesPages().model
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(emptyMoviesPage), when: {
            store.completeRetrieval(with: cachedMoviesPage, timestamp: moreThanSevenDaysOldTimeStamp)
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
    
    func test_load_whenCacheIsLessThanSevenDaysOld_shouldNotDeleteCache() {
        let moviesPage = uniqueMoviesPages()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: moviesPage.cache, timestamp: lessThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_whenCacheIsSevenDaysOld_shouldDeleteCache() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let fixedCurrentDate = Date()
        let sevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: cachedMoviesPage, timestamp: sevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_whenCacheIsMoreThanSevenDaysOld_shouldDeleteCache() {
        let cachedMoviesPage = uniqueMoviesPages().cache
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: cachedMoviesPage, timestamp: moreThanSevenDaysOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
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
        
        trackForMemoryLeaks(store)
        trackForMemoryLeaks(sut)
        
        return (sut, store)
    }
    
    private func emptyMoviesPages() -> (model: MoviesPage, cache: CacheMoviesPage) {
        let model = MoviesPage(
            page: 1,
            results: [],
            totalResults: 1,
            totalPages: 1
        )
        let cache = CacheMoviesPage.init(from: model)
        
        return (model, cache)
    }
    
    private func uniqueMoviesPages() -> (model: MoviesPage, cache: CacheMoviesPage) {
        let model = uniqueMoviesPage()
        let cache = CacheMoviesPage.init(from: model)
        
        return (model, cache)
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

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
