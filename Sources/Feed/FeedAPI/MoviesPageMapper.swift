import Foundation

final class MoviesPageMapper {
    
    // MARK: - Private Properties
    
    private static var OK_200: Int { return 200}
    
    // MARK: - API
    
    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> RemoteMoviesPage {
        guard
            response.statusCode == OK_200,
            let moviesPageDTO = try? JSONDecoder().decode(RemoteMoviesPage.self, from: data)
        else {
            throw RemoteMoviesPageLoader.Error.invalidData
        }
        
        return moviesPageDTO
    }
}

struct RemoteMoviesPage: Decodable {
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
    
    let page: Int
    let results: [RemoteMovie]
    let totalResults: Int
    let totalPages: Int
}

struct RemoteMovie: Decodable {
    let id: Int
    let title: String
}
