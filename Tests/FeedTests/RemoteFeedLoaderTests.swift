import Feed
import XCTest

class RemoteFeedLoaderTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_init_whenCalled_shouldNotRequestDataFromUrl() {
        let (_, client) = makeSut()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_whenCalled_shouldRequestDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_whenCalledTwice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_shouldReturnErrorOnClientError() {
        let (sut, client) = makeSut()
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
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
        
        // MARK: - Private Properties
        
        private var messages = [(url: URL, completion: (Error) -> Void)]()
        
        // MARK: - Public Properties
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
                
        // MARK: - API
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error)
        }
    }
}
