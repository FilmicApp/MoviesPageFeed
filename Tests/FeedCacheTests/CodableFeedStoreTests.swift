import FeedCache
import XCTest

class CodableFeedStore {
    
    // MARK: - Private Properties
    
    private let storeURL: URL
    
    // MARK: - Init
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    
    // MARK: - API
    
    func insert(_ moviesPage: CacheMoviesPage, timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let codableMoviesPage = CodableMoviesPage(moviesPage)
        let cache = Cache(moviesPage: codableMoviesPage, timestamp: timestamp)
        let encodedValues = try! encoder.encode(cache)
        try! encodedValues.write(to: storeURL)
        
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let codableCache = try! decoder.decode(Cache.self, from: data)
        let cacheMoviesPage = codableCache.moviesPage.toCacheMoviesPage()
        completion(.found(moviesPage: cacheMoviesPage, timestamp: codableCache.timestamp))
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        setUpEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreArtefacts()
    }
    
    // MARK: - Tests
    
    func test_retrieve_whenCacheIsEmpty_shouldDeliverEmpty() {
        let sut = makeSut()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_whenCacheIsEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        let expectation = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                    
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieve_whenCallingAfterInsertingToCache_shouldDeliverInsertedValues() {
        let sut = makeSut()
        let moviesPage = uniqueMoviesPages().cache
        let timestamp = Date()
        
        let expectation = expectation(description: "Wait for cache retrieval")
        sut.insert(moviesPage, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        expect(sut, toRetrieve: .found(moviesPage: moviesPage, timestamp: timestamp))
    }
    
    func test_retrieve_whenCacheIsNonEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        let moviesPage = uniqueMoviesPages().cache
        let timestamp = Date()
        let expectation = expectation(description: "Wait for cache retrieval")
        
        sut.insert(moviesPage, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            
            sut.retrieve { firstRetrievedResult in
                sut.retrieve { secondRetrievedResult in
                    switch (firstRetrievedResult, secondRetrievedResult) {
                    case let (.found(expectedMoviesPage, expectedTimestamp), .found(retrievedMoviesPage, retrievedTimestamp)):
                        XCTAssertEqual(expectedMoviesPage, retrievedMoviesPage)
                        XCTAssertEqual(expectedTimestamp, retrievedTimestamp)
                        
                    default:
                        XCTFail("Expected retrieving twice from a non-empty cache to deliver the same found result with moviesPage \(moviesPage) and timestamp \(timestamp), but got \(firstRetrievedResult) and \(secondRetrievedResult) instead")
                    }
                    
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    // MARK: - Factory methods
    
    func makeSut(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    // MARK: - Helpers
    
    private func setUpEmptyStoreState() {
        deleteStoreArtefact()
    }
    
    private func undoStoreArtefacts() {
        deleteStoreArtefact()
    }
    
    private func deleteStoreArtefact() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func expect(
        _ sut: CodableFeedStore,
        toRetrieve expectedResult: RetrievedCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty):
                break
                
            case let (.found(expectedMoviesPage, expectedTimestamp), .found(retrievedMoviesPage, retrievedTimestamp)):
                XCTAssertEqual(expectedMoviesPage, retrievedMoviesPage)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            
            expectation.fulfill()
        }
        
        
        wait(for: [expectation], timeout: 1.0)
    }
}

extension CodableFeedStore {
    private struct Cache: Codable {
        let moviesPage: CodableMoviesPage
        let timestamp: Date
        
        var cacheMoviesPage: CacheMoviesPage {
            return moviesPage.toCacheMoviesPage()
        }
    }
    
    private struct CodableMoviesPage: Codable {
        
        // MARK: - Private Properties
        
        private let page: Int
        private let results: [CodableMovie]
        private let totalResults: Int
        private let totalPages: Int
        
        // MARK: - Init
        
        init(_ moviesPage: CacheMoviesPage) {
            self.page = moviesPage.page
            self.results = moviesPage.results.map { CodableMovie($0) }
            self.totalResults = moviesPage.totalResults
            self.totalPages = moviesPage.totalPages
        }
        
        // MARK: - API
        
        func toCacheMoviesPage() -> CacheMoviesPage {
            CacheMoviesPage(
                page: self.page,
                results: self.results.map { $0.toCacheMovie() },
                totalResults: self.totalResults,
                totalPages: self.totalPages
            )
        }
    }
    
    private struct CodableMovie: Codable {
        
        // MARK: - Private Properties
        
        private let id: Int
        private let title: String
        
        // MARK: - Init
        
        init(_ movie: CacheMovie) {
            self.id = movie.id
            self.title = movie.title
        }
        
        // MARK: - API
        
        func toCacheMovie() -> CacheMovie {
            CacheMovie(
                id: self.id,
                title: self.title
            )
        }
    }
}
