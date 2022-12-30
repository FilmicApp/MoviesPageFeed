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
    
    func test_load_whenReceivesNonEmptyMoviesPageJSONWith200HTTPResponse_shouldDeliverNonEmptyMoviesPage() throws {
        let (sut, client) = makeSut()
        
        let moviesPageTestObjects = makeMoviesPageWithData(
            page: 1,
            results: [
                makeMovieWithJSON(id: 1, title: "Title1"),
                makeMovieWithJSON(id: 2, title: "Title2")
            ],
            totalResults: 2,
            totalPages: 1
        )
        
        expect(sut, toCompleteWithResult: .success(moviesPageTestObjects.model), when: {
            client.complete(withStatusCode: 200, data: moviesPageTestObjects.data)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSut(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func makeMovieWithJSON(id: Int, title: String) -> (model: Movie, json: [String: Any]) {
        let model = Movie(id: id, title: title)
        
        let json: [String: Any] = [
            "id": id,
            "title": title
        ]
        
        return (model, json)
    }
    
    private func makeMoviesPageWithData(
        page: Int,
        results: [(model: Movie, json: [String: Any])] = [],
        totalResults: Int,
        totalPages: Int)
    -> (model: MoviesPage, data: Data) {
        let model = MoviesPage(
            page: page,
            results: results.map { $0.model },
            totalResults: totalResults,
            totalPages: totalPages
        )
        
        let json: [String: Any] = [
            "page": page,
            "results": results.map { $0.json },
            "totalResults": totalResults,
            "totalPages": totalPages
        ]
        
        let data = try! JSONSerialization.data(withJSONObject: json)
        
        return (model, data)
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

private extension Movie {
    func toJson() -> [String: Any] {
        return [
            "id": self.id,
            "title": self.title
        ]
    }
}
