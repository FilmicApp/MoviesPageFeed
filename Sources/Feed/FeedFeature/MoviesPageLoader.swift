public enum LoadMoviesPageResult {
    case success(MoviesPage)
    case failure(Error)
}

protocol MoviesPageLoader {
    func load(completion: @escaping (LoadMoviesPageResult) -> Void)
}

