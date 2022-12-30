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
            case let .success(data, response):
                if response.statusCode == 200, let moviesPageDTO = try? JSONDecoder().decode(MoviesPageDTO.self, from: data) {
                    completion(.success(moviesPageDTO.toDomain()))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private struct MoviesPageDTO: Decodable {
    let page: Int
    let results: [MovieDTO]
    let totalResults: Int
    let totalPages: Int
    
    func toDomain() -> MoviesPage {
        MoviesPage(
            page: self.page,
            results: self.results.map { $0.toDomain() },
            totalResults: self.totalResults,
            totalPages: self.totalPages
        )
    }
}

private struct MovieDTO: Decodable {
    
    let id: Int
    let title: String
    
    func toDomain() -> Movie {
        Movie(
            id: self.id,
            title: self.title
        )
    }
}
