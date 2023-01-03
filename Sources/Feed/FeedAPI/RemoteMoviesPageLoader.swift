import Foundation

public final class RemoteMoviesPageLoader: MoviesPageLoader {
    
    public typealias Result = LoadMoviesPageResult
    public typealias Completion = (Result) -> Void

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
    
    public func load(completion: @escaping Completion) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(data, response):
                completion(RemoteMoviesPageLoader.map(data, from: response))
            case .failure:
                completion(RemoteMoviesPageLoader.handleFailure())
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        do {
            let remoteMoviesPage = try MoviesPageMapper.map(data, from: response)
            return .success(remoteMoviesPage.toDomain())
        } catch {
            return .failure(error)
        }
    }
        
    private static func handleFailure() -> Result {
        .failure(Error.connectivity)
    }
}

private extension RemoteMoviesPage {
    func toDomain() -> MoviesPage {
        MoviesPage(
            page: self.page,
            results: self.results.map { $0.toDomain() },
            totalResults: self.totalResults,
            totalPages: self.totalPages
        )
    }
}

private extension RemoteMovie {
    func toDomain() -> Movie {
        Movie(
            id: self.id,
            title: self.title
        )
    }
}
