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
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_whenCalledTwice_shouldRequestDataFromUrlTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSut(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_shouldDeliverErrorOnClientError() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWithError: .connectivity, when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_shouldDeliverErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSut()
        
        let statusCodeSamples = [199, 201, 300, 400, 500]
        
        statusCodeSamples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithError: .invalidData, when: {
                client.complete(withStatusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_shouldDeliverErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSut()

        expect(sut, toCompleteWithError: .invalidData, when: {
            let invalidJson = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        })
    }
    
    func test_load_shouldDeliverNoItemsOn200HTTPResponseWithEmptyJsonPage() {
        let (sut, client) = makeSut()
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        let emptyMoviesPageJson = Data("{\"page\": 1,\"results\":[],\"totalResults\":0,\"totalPages\":1}".utf8)
        let emptyMoviesPage = MoviesPage(page: 1, results: [], totalResults: 0, totalPages: 1)
        client.complete(withStatusCode: 200, data: emptyMoviesPageJson)
        
        XCTAssertEqual(capturedResults, [.success(emptyMoviesPage)])
    }
    
    // MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [.failure(error)], file: file, line: line)
    }
}

extension RemoteFeedLoaderTests {
    private class HTTPClientSpy: HTTPClient {
        
        // MARK: - Private Properties
        
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        // MARK: - Public Properties
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        // MARK: - API
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            
            messages[index].completion(.success(data, response))
        }
    }
}
