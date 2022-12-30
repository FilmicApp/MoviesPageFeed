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
                self.handleSuccess(data, response, completion)
            case .failure:
                self.handleFailure(completion)
            }
        }
    }
    
    private func handleSuccess(
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
    
    private func handleFailure(_ completion: @escaping (Result) -> Void) {
        completion(.failure(.connectivity))
    }
}

private class MoviesPageMapper {
    
    // MARK: - Private Structs
    
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
    
    private static var OK_200: Int { return 200}
    
    // MARK: - API
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> MoviesPage {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        let moviesPageDTO =  try JSONDecoder().decode(MoviesPageDTO.self, from: data)
        
        return moviesPageDTO.toDomain()
    }
}
