import Foundation

final class MoviesPageMapper {
    
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
