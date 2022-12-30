public enum LoadMoviesPageResult<Error: Swift.Error> {
    case success(MoviesPage)
    case failure(Error)
}

protocol MoviesPageLoader {
    associatedtype Error: Swift.Error
    
    func load(completion: @escaping (LoadMoviesPageResult<Error>) -> Void)
}

