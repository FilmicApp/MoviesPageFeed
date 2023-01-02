import XCTest

class LocalFeedLoader {
    init(store: FeedStore) {
        
    }
}

class FeedStore {
    let deleteCachedFeedCallCount = 0
}

class CacheFeedUseCase: XCTestCase {
    
    func test_init_shouldNotDeleteCacheUponInitialisation() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
