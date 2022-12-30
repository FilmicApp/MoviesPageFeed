import XCTest

class URLSessionHTTPClient {
    
    // MARK: - Private Properties
    
    private let session: URLSession
    
    // MARK: - Init

    init(session: URLSession) {
        self.session = session
    }
    
    // MARK: - API
    
    func get(from url: URL) {
        session.dataTask(with: url) { _, _, _ in }
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    // MARK: - Tests
    
    func test_getFromURL_createsDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    // MARK: - Helpers

    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            
            return FakeURLSessionDataTask()
        }
        
        private class FakeURLSessionDataTask: URLSessionDataTask {}
    }
}

