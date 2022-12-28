import XCTest
@testable import Feed

class RemoteFeedLoader {
    
    private let client: HTTPClient
    private let url: URL
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        self.client.get(from: self.url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class RemoteFeedLoaderTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_whenInitialised_shouldNotRequestDataFromUrl() {
        let (_, client) = makeSut()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_whenLoadFunctionCalled_shouldRequestDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
    
    // MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
}

extension RemoteFeedLoaderTests {
    private class HTTPClientSpy: HTTPClient {
        
        var requestedURL: URL?

        func get(from url: URL) {
            requestedURL = url
        }
    }
}
