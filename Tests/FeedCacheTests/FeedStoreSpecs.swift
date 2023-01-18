protocol FeedStoreSpecs {
    func test_retrieve_whenCacheIsEmpty_shouldDeliverEmpty()
    func test_retrieve_whenCacheIsEmpty_shouldHaveNoSideEffects()
    func test_retrieve_whenCacheIsNonEmpty_shouldDeliverFoundValues()
    func test_retrieve_whenCacheIsNonEmpty_shouldHaveNoSideEffects()
    
    func test_insert_whenCacheIsNonEmpty_shouldOverridePreviouslyInsertedCachedValues()
    
    func test_delete_whenCacheIsEmpty_shouldHaveNoSideEffects()
    func test_delete_whenCacheIsNonEmpty_shouldEmptyPreviouslyInsertedCachedValues()
    
    func test_sideEffects_whenRun_shouldRunSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retrieve_whenReceivesRetrievalError_shouldDeliverFailure()
    func test_retrieve_whenReceivesRetrievalError_shouldHaveNoSideEffects()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
    func test_insert_whenReceivesInsertionError_shouldDeliverError()
    func test_insert_whenReceivesInsertionError_shouldHaveNoSideEffects()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_whenReceivesDeletionError_shouldDeliverError()
    func test_delete_whenReceivesDeletionError_shouldHaveNoSideEffects()
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs
