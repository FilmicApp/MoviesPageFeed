import FeedCache
import XCTest

class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
    
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
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSut(storeURL: invalidStoreURL)
        let cache = makeUniqueCacheableTuple()

        let insertionError = insert(cache, to: sut)
        
        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with error")
    }
    
    func test_insert_whenReceivesInsertionError_shouldHaveNoSideEffects() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSut(storeURL: invalidStoreURL)
        let cache = makeUniqueCacheableTuple()

        insert(cache, to: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_whenCacheIsEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_whenCacheIsNonEmpty_shouldEmptyPreviouslyInsertedCachedValues() {
        let sut = makeSut()
        insert(makeUniqueCacheableTuple(), to: sut)
        
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_whenReceivesDeletionError_shouldDeliverError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSut(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }
    
    func test_delete_whenReceivesDeletionError_shouldHaveNoSideEffects() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSut(storeURL: noDeletePermissionURL)
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_sideEffects_whenRun_shouldRunSerially() {
        let sut = makeSut()
        let (moviesPage, timestamp) = makeUniqueCacheableTuple()
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert(moviesPage, timestamp: timestamp) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(moviesPage, timestamp: timestamp) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side effects to run serially, but operations finished in the wrong order")
    }
    
    // MARK: - Factory methods
    
    private func makeSut(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
}
