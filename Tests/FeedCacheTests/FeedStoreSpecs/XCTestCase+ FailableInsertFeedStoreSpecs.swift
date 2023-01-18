import XCTest
import FeedCache

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let cache = makeUniqueCacheableTuple()
        let insertionError = insert(cache, to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }

    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let cache = makeUniqueCacheableTuple()
        insert(cache, to: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
}
