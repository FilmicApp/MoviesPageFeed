struct MoviesPage {
    let page: Int
    let results: [Movie]
    let totalResults: Int
    let totalPages: Int
}

struct Movie: Decodable {
    let id: Int
    let title: String
}
