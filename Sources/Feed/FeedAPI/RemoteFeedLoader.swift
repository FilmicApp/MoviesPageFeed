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
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                RemoteFeedLoader.handleSuccess(data, response, completion)
            case .failure:
                RemoteFeedLoader.handleFailure(completion)
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func handleSuccess(
        _ data: Data,
        _ response: HTTPURLResponse,
        _ completion: @escaping (Result) -> Void
    ) {
        do {
            let moviesPage = try MoviesPageMapper.map(data, response)
            completion(.success(moviesPage))
        } catch {
            completion(.failure(.invalidData))
        }
    }
    
    private static func handleFailure(_ completion: @escaping (Result) -> Void) {
        completion(.failure(.connectivity))
    }
}
