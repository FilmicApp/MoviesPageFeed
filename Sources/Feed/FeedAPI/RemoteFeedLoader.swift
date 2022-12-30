import Foundation

public final class RemoteFeedLoader {
    
    // MARK: - Enums
    
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
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(data, response):
                completion(RemoteFeedLoader.handleSuccess(data, response))
            case .failure:
                completion(RemoteFeedLoader.handleFailure())
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func handleSuccess(_ data: Data, _ response: HTTPURLResponse) -> Result {
        MoviesPageMapper.map(data, from: response)
    }
        
    private static func handleFailure() -> Result {
        .failure(.connectivity)
    }
}
