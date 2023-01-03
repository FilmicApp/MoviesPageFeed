import Feed
import XCTest

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    
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
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_whenReceivesNon200HTTPResponse_shouldDeliverError() {
        let (sut, client) = makeSut()
        
        let statusCodeSamples = [199, 201, 300, 400, 500]
        
        statusCodeSamples.enumerated().forEach { index, statusCode in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let emptyMoviesPage = makeMoviesPageWithData()
                client.complete(withStatusCode: statusCode, data: emptyMoviesPage.data, at: index)
            })
        }
    }
    
    func test_load_whenReceives200HTTPResponseWithInvalidJSON_shouldDeliverError() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJson = Data("invalid data".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        })
    }
    
    func test_load_whenReceivesEmptyMoviesPageJSONWith200HTTPResponse_shouldDeliverEmptyMoviesPage() {
        let (sut, client) = makeSut()
        
        let emptyMoviesPage = MoviesPage(page: 1, results: [], totalResults: 0, totalPages: 1)
        expect(sut, toCompleteWith: .success(emptyMoviesPage), when: {
            let emptyMoviesPage = makeMoviesPageWithData()
            client.complete(withStatusCode: 200, data: emptyMoviesPage.data)
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
        
        expect(sut, toCompleteWith: .success(moviesPageTestObjects.model), when: {
            client.complete(withStatusCode: 200, data: moviesPageTestObjects.data)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSutInstanceHasBeenDeallocated() {
        let url = URL(string: "https://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteMoviesPageLoader? = RemoteMoviesPageLoader(url: url, client: client)
        
        var capturedResults = [RemoteMoviesPageLoader.Result]()
        sut?.load { capturedResults.append($0) }

        sut = nil
        client.complete(withStatusCode: 200, data: makeMoviesPageWithData().data)

        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Factory methods
    
    private func makeSut(
        url: URL = URL(string: "https://a-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteMoviesPageLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMoviesPageLoader(url: url, client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
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
        page: Int = 1,
        results: [(model: Movie, json: [String: Any])] = [],
        totalResults: Int = 0,
        totalPages: Int = 1)
    -> (model: MoviesPage, data: Data) {
        let model = MoviesPage(
            page: page,
            results: results.map { $0.model },
            totalResults: totalResults,
            totalPages: totalPages
        )
        
        let json = makeMoviesPageJSON(
            page: page,
            results: results.map { $0.json },
            totalResults: totalResults,
            totalPages: totalPages
        )
        
        let data = makeMoviesPageJSONData(from: json)
        
        return (model, data)
    }
    
    private func makeMoviesPageJSON(
        page: Int,
        results: [[String: Any]],
        totalResults: Int,
        totalPages: Int)
    -> [String: Any] {
        [
            "page": page,
            "results": results,
            "total_results": totalResults,
            "total_pages": totalPages
        ]
    }
    
    private func makeMoviesPageJSONData(from json: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    // MARK: - Helpers
    
    private func failure(_ error: RemoteMoviesPageLoader.Error) -> RemoteMoviesPageLoader.Result {
        .failure(error)
    }
        
    private func expect(
        _ sut: RemoteMoviesPageLoader,
        toCompleteWith expectedResult: RemoteMoviesPageLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = expectation(description: "Wait for load completion")
        
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedMoviesPage), .success(expectedMoviesPage)):
                XCTAssertEqual(receivedMoviesPage, expectedMoviesPage, file: file, line: line)
                
            case let (.failure(receivedError as RemoteMoviesPageLoader.Error), .failure(expectedError as RemoteMoviesPageLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected result \(expectedResult), but got \(receivedResult) instead", file: file, line: line)
            }
            
            expectation.fulfill()
        }
        
        action()
        
        wait(for: [expectation], timeout: 1)
    }
}

extension LoadFeedFromRemoteUseCaseTests {
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
        
        func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
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
