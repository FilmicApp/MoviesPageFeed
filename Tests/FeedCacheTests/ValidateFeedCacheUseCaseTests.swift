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
    
    func test_validateCache_whenCacheIsLessThanSevenDaysOld_shouldNotDeleteCache() {
        let moviesPage = uniqueMoviesPages()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimeStamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: moviesPage.cache, timestamp: lessThanSevenDaysOldTimeStamp)
        
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
    
    // MARK: - Helpers
    
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
