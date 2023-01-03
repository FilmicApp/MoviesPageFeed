import FeedCache
import XCTest

class CodableFeedStore {
    
    private struct Cache: Codable {
        let moviesPage: CacheMoviesPage
        let timestamp: Date
    }
    
    // MARK: - Private Properties
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    // MARK: - API
    
    func insert(_ moviesPage: CacheMoviesPage, timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encodedValues = try! encoder.encode(Cache(moviesPage: moviesPage, timestamp: timestamp))
        try! encodedValues.write(to: storeURL)
        
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(moviesPage: cache.moviesPage, timestamp: cache.timestamp))
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeUrl)
    }
    
    override func tearDown() {
        super.tearDown()
        
        let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeUrl)
    }
    
    // MARK: - Tests
    
    func test_retrieve_whenCacheIsEmpty_shouldDeliverEmpty() {
        let sut = CodableFeedStore()
        let expectation = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
                
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_retrieve_whenCacheIsEmpty_shouldHaveNoSideEffects() {
        let sut = CodableFeedStore()
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
        let sut = CodableFeedStore()
        let moviesPage = uniqueMoviesPages().cache
        let timestamp = Date()
        let expectation = expectation(description: "Wait for cache retrieval")
        
        sut.insert(moviesPage, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            
            sut.retrieve { retrieveResult in
                switch retrieveResult {
                case let .found(retrievedMoviesPage, retrievedTimestamp):
                    XCTAssertEqual(retrievedMoviesPage, moviesPage)
                    XCTAssertEqual(retrievedTimestamp, timestamp)
                default:
                    XCTFail("Expected found result with moviesPage \(moviesPage) and timestamp \(timestamp), got \(retrieveResult) instead")
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
