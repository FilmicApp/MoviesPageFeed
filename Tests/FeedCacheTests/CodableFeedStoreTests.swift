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
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeletionCompletion) {
        
    }
    
    func insert(_ moviesPage: CacheMoviesPage, timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let codableMoviesPage = CodableMoviesPage(moviesPage)
            let cache = Cache(moviesPage: codableMoviesPage, timestamp: timestamp)
            let encodedValues = try encoder.encode(cache)
            try encodedValues.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let codableCache = try decoder.decode(Cache.self, from: data)
            let cacheMoviesPage = codableCache.moviesPage.toCacheMoviesPage()
            completion(.found(moviesPage: cacheMoviesPage, timestamp: codableCache.timestamp))
        } catch {
            completion(.failure(error))
        }
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
        
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_whenCacheIsNonEmpty_shouldDeliverFoundValues() {
        let sut = makeSut()
        let moviesPage = uniqueMoviesPages().cache
        let timestamp = Date()
        
        insert((moviesPage, timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(moviesPage: moviesPage, timestamp: timestamp))
    }
    
    func test_retrieve_whenCacheIsNonEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        let moviesPage = uniqueMoviesPages().cache
        let timestamp = Date()
        
        insert((moviesPage, timestamp), to: sut)
                
        expect(sut, toRetrieve: .found(moviesPage: moviesPage, timestamp: timestamp))
    }
    
    func test_retrieve_whenReceivesRetrievalError_shouldDeliverFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyNSError()))
    }
        
    func test_retrieve_whenReceivesRetrievalError_shouldHaveNoSideEffects() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }
    
    func test_insert_whenCacheIsNonEmpty_shouldOverridePreviouslyInsertedCachedValues() {
        let sut = makeSut()
        let firstCache = makeUniqueCacheableTuple()
        
        let firstInsertionError = insert(firstCache, to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")
        
        let latestCache = makeUniqueCacheableTuple()
        let latestInsertionError = insert(latestCache, to: sut)
        
        XCTAssertNil(latestInsertionError, "Expected to override cache successfully")
        expect(sut, toRetrieve: .found(moviesPage: latestCache.moviesPage, timestamp: latestCache.timestamp))
    }
    
    func test_insert_whenReceivesInsertionError_shouldDeliverError() {
        let storeURL = URL(string: "invalid://store-url")!
        let sut = makeSut(storeURL: storeURL)
        let cache = makeUniqueCacheableTuple()

        let insertionError = insert(cache, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with error")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSut()
        
        var deletionError: Error?
        sut.deleteCachedFeed { receivedError in
            deletionError = receivedError
        }
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    // MARK: - Factory methods
    
    private func makeSut(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func makeUniqueCacheableTuple() -> (moviesPage: CacheMoviesPage, timestamp: Date) {
        let moviesPage = uniqueMoviesPages().cache
        let timestamp = Date()
        return (moviesPage, timestamp)
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
    
    @discardableResult
    private func insert(_ cache: (moviesPage: CacheMoviesPage, timestamp: Date), to sut: CodableFeedStore) -> Error? {
        let expectation = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.moviesPage, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return insertionError
    }
    
    private func expect(
        _ sut: CodableFeedStore,
        toRetrieveTwice expectedResult: RetrievedCachedFeedResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
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
            case (.empty, .empty),
                 (.failure, .failure):
                break
                
            case let (.found(expectedMoviesPage, expectedTimestamp), .found(retrievedMoviesPage, retrievedTimestamp)):
                XCTAssertEqual(expectedMoviesPage, retrievedMoviesPage, file: file, line: line)
                XCTAssertEqual(expectedTimestamp, retrievedTimestamp, file: file, line: line)
                
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
