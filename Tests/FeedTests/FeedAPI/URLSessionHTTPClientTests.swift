import Feed
import XCTest

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask
}

protocol HTTPSessionDataTask {
    func resume()
}

class URLSessionHTTPClient {
    
    // MARK: - Private Properties
    
    private let session: HTTPSession
    
    // MARK: - Init

    init(session: HTTPSession) {
        self.session = session
    }
    
    // MARK: - API
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    // MARK: - Tests
        
    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let task = HTTPSessionDataTaskSpy()
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "https://any-url.com")!
        let session = HTTPSessionSpy()
        let expectedError = NSError(domain: "any error", code: 1)
        session.stub(url: url, error: expectedError)
        let sut = URLSessionHTTPClient(session: session)
        
        let expectation = expectation(description: "Wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(expectedError, receivedError)
            default:
                XCTFail("Expected failure with error \(expectedError), got \(result) instead")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    private class HTTPSessionSpy: HTTPSession {
        
        private struct Stub {
            let task: HTTPSessionDataTask
            let error: Error?
        }

        // MARK: - Private Properties
        
        private var stubs = [URL: Stub]()
        
        // MARK: - API
        
        func stub(url: URL, task: HTTPSessionDataTask = FakeHTTPSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    private class FakeHTTPSessionDataTask: HTTPSessionDataTask {
        func resume() {}
    }

    private class HTTPSessionDataTaskSpy: HTTPSessionDataTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }

}
