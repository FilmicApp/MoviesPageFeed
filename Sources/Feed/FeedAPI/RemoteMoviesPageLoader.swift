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
                RemoteMoviesPageLoader.handleSuccess(data, response, with: completion)
            case .failure:
                RemoteMoviesPageLoader.handleFailure(with: completion)
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func handleSuccess(_ data: Data, _ response: HTTPURLResponse, with completion: (Result) -> Void) {
        do {
            let remoteMoviesPage = try MoviesPageMapper.map(data, from: response)
            completion(.success(remoteMoviesPage.toModels()))
        } catch {
            completion(.failure(error))
        }
    }
        
    private static func handleFailure(with completion: (Result) -> Void) {
        completion(.failure(Error.connectivity))
    }
}

private extension RemoteMoviesPage {
    func toModels() -> MoviesPage {
        MoviesPage(
            page: self.page,
            results: self.results.map { $0.toModels() },
            totalResults: self.totalResults,
            totalPages: self.totalPages
        )
    }
}

private extension RemoteMovie {
    func toModels() -> Movie {
        Movie(
            id: self.id,
            title: self.title
        )
    }
}
