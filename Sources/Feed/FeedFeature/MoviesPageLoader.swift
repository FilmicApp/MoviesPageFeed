public enum LoadMoviesPageResult {
    case success(MoviesPage)
    case failure(Error)
}

public protocol MoviesPageLoader {
    func load(completion: @escaping (LoadMoviesPageResult) -> Void)
}

