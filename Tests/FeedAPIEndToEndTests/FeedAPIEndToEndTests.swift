import Foundation

import Feed
import XCTest

class FeedAPIEndToEndTests: XCTestCase {
    
    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        let testServerURL = URL(string: "https://any-url.com")!
        let client = URLSessionHTTPClient()
        let loader = RemoteMoviesPageLoader(url: testServerURL, client: client)
        
        let expectation = expectation(description: "Wait for load completion")
        
        var receivedResult: LoadMoviesPageResult?
        loader.load { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        switch receivedResult {
        case let .success(moviesPage)?:
            XCTAssertEqual(moviesPage.page, 1, "Expected 1 item in the test account feed")
//            XCTAssertEqual(moviesPage.results, results)
            XCTAssertEqual(moviesPage.totalPages, 1)
            XCTAssertEqual(moviesPage.totalResults, 1)
        case let .failure(error)?:
            XCTFail("Expected successful moviesPage result, got \(error) instead")
        default:
            XCTFail("Expected successful moviesPage result, got no result instead")
        }
    }
}
