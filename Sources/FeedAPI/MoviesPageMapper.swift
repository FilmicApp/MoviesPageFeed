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
