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
    
    // MARK: - Tests: Retrieve
    
    func test_retrieve_whenCacheIsEmpty_shouldDeliverEmpty() {
        let sut = makeSut()
        
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_whenCacheIsEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_whenCacheIsNonEmpty_shouldDeliverFoundValues() {
        let sut = makeSut()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_whenCacheIsNonEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_whenReceivesRetrievalError_shouldDeliverFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)
        
        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
    }
    
    func test_retrieve_whenReceivesRetrievalError_shouldHaveNoSideEffects() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSut(storeURL: storeURL)
        
        try! "invalidData".write(to: storeURL, atomically: false, encoding: .utf8)
        
        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    // MARK: - Tests: Insert
    
    func test_insert_whenCacheIsEmpty_shouldDeliverNoError() {
        let sut = makeSut()
        
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_insert_whenCacheIsNonEmpty_shouldDeliverNoError() {
        let sut = makeSut()
        
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_insert_whenCacheIsNonEmpty_shouldOverridePreviouslyInsertedCachedValues() {
        let sut = makeSut()
        
        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_insert_whenReceivesInsertionError_shouldDeliverError() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSut(storeURL: invalidStoreURL)
        
        assertThatInsertDeliversErrorOnInsertionError(on: sut)
    }
    
    func test_insert_whenReceivesInsertionError_shouldHaveNoSideEffects() {
        let invalidStoreURL = URL(string: "invalid://store-url")!
        let sut = makeSut(storeURL: invalidStoreURL)
        
        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
    }
    
    // MARK: - Tests: Delete
    
    func test_delete_whenCacheIsEmpty_shouldDeliverNoError() {
        let sut = makeSut()
        
        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_whenCacheIsEmpty_shouldHaveNoSideEffects() {
        let sut = makeSut()
        
        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_delete_whenCacheIsNonEmpty_shouldDeliverNoError() {
        let sut = makeSut()
        
        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_delete_whenCacheIsNonEmpty_shouldEmptyPreviouslyInsertedCachedValues() {
        let sut = makeSut()
        
        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }
    
    func test_delete_whenReceivesDeletionError_shouldDeliverError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSut(storeURL: noDeletePermissionURL)
        
        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
    }
    
    func test_delete_whenReceivesDeletionError_shouldHaveNoSideEffects() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSut(storeURL: noDeletePermissionURL)
        
        assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
    }
    
    // MARK: - Tests: Side Effects
    
    func test_sideEffects_whenRun_shouldRunSerially() {
        let sut = makeSut()
        
        assertThatSideEffectsRunSerially(on: sut)
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
