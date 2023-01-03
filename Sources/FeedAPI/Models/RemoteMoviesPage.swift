import Foundation

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
