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
    
    func test_load_whenReceivesClientError_shouldDeliverError() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWithResult: .failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_whenReceivesNon200HTTPResponse_shouldDeliverError() {
        let (sut, client) = makeSut()
        
        let statusCodeSamples = [199, 201, 300, 400, 500]
        
        statusCodeSamples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
                client.complete(withStatusCode: statusCode, at: index)
            })
        }
    }
    
    func test_load_whenReceives200HTTPResponseWithInvalidJSON_shouldDeliverError() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
            let invalidJson = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        })
    }
    
    func test_load_whenReceivesEmptyMoviesPageJSONWith200HTTPResponse_shouldDeliverEmptyMoviesPage() {
        let (sut, client) = makeSut()
        
        let emptyMoviesPage = MoviesPage(page: 1, results: [], totalResults: 0, totalPages: 1)
        expect(sut, toCompleteWithResult: .success(emptyMoviesPage), when: {
            let emptyMoviesPageJson = Data("{\"page\": 1,\"results\":[],\"totalResults\":0,\"totalPages\":1}".utf8)
            client.complete(withStatusCode: 200, data: emptyMoviesPageJson)
        })
    }
    
    func test_load_whenReceivesNonEmptyMoviesPageJSONWith200HTTPResponse_shouldDeliverNonEmptyMoviesPage() {
        let (sut, client) = makeSut()
        
        let movie1 = Movie(id: 1, title: "Title1")
        let movie2 = Movie(id: 2, title: "Title2")
        
        let moviesPage = MoviesPage(
            page: 1,
            results: [movie1, movie2],
            totalResults: 2,
            totalPages: 1
        )
        
        expect(sut, toCompleteWithResult: .success(moviesPage), when: {
            let jsonData = try! JSONEncoder().encode(moviesPage)
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
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

extension Movie {
    func toJson() -> String? {
        guard let encodedData = try? JSONEncoder().encode(self) else { return nil }
        return String(data: encodedData, encoding: .utf8)
    }
}

extension MoviesPage {
    func toJsonData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    func toJsonString() -> String? {
        guard let encodedData = self.toJsonData() else { return nil}
        return String(data: encodedData, encoding: .utf8)
    }
}
