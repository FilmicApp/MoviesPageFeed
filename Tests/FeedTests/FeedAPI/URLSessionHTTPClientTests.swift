import Feed
import XCTest

class URLSessionHTTPClient {
    
    struct UnexpectedValuesRepresentation: Error {}
    
    // MARK: - Private Properties
    
    private let session: URLSession
    
    // MARK: - Init

    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - API
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequests()
        
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyUrl()
        let expectation = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        
        makeSut().get(from: url) { _ in }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let expectedError = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        
        let sut = makeSut()
        
        let expectation = expectation(description: "Wait for completion")
        sut.get(from: anyUrl()) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(expectedError.domain, receivedError.domain)
                XCTAssertEqual(expectedError.code, receivedError.code)
            default:
                XCTFail("Expected failure with error \(expectedError), got \(result) instead")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnAllNilValues() {
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        
        let sut = makeSut()
        
        let expectation = expectation(description: "Wait for completion")
        sut.get(from: anyUrl()) { result in
            switch result {
            case .failure:
                break
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Factory methods
    
    private func makeSut(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyUrl() -> URL {
        URL(string: "https://any-url.com")!
    }
}

private class URLProtocolStub: URLProtocol {
    
    // MARK: - Private Structs
    
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    // MARK: - Private Properties
    
    private static var stub: Stub?
    private static var requestObserver: ((URLRequest) -> Void)?
    
    // MARK: - API
    
    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        stub = Stub(data: data, response: response, error: error)
    }
    
    static func observeRequests(observer: @escaping (URLRequest) -> Void) {
        requestObserver = observer
    }
    
    static func startInterceptingRequests() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequests() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        requestObserver?(request)
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let data = URLProtocolStub.stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = URLProtocolStub.stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = URLProtocolStub.stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}
