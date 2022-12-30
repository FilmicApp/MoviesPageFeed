import Foundation

public final class RemoteMoviesPageLoader: MoviesPageLoader {
    
    public typealias Result = LoadMoviesPageResult

    // MARK: - Enums
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
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
                completion(RemoteMoviesPageLoader.handleSuccess(data, response))
            case .failure:
                completion(RemoteMoviesPageLoader.handleFailure())
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func handleSuccess(_ data: Data, _ response: HTTPURLResponse) -> Result {
        MoviesPageMapper.map(data, from: response)
    }
        
    private static func handleFailure() -> Result {
        .failure(Error.connectivity)
    }
}
