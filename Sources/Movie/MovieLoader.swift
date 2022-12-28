enum LoadMovieResult {
    case success([Movie])
    case failure(Error)
}

protocol MovieLoader {
    func load(completion: @escaping (LoadMovieResult) -> Void)
}
