public struct MoviesPage: Decodable, Equatable {
    let page: Int
    let results: [Movie]
    let totalResults: Int
    let totalPages: Int
}

public struct Movie: Decodable, Equatable {
    let id: Int
    let title: String
}
