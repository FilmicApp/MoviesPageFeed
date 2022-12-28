import XCTest
@testable import Feed

class RemoteFeedLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_whenInitialised_shouldNotRequestDataFromURL() {
        let client = HTTPClient()
        let sut = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
