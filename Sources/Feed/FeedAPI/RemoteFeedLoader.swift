import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success(MoviesPage)
        case failure(Error)
    }
    
    // MARK: - Private Properties
    
    private let url: URL
    private let client: HTTPClient
    
    // MARK: - Init
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    // MARK: - API
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, _):
                if let page = try? JSONDecoder().decode(MoviesPage.self, from: data) {
                    completion(.success(page))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
