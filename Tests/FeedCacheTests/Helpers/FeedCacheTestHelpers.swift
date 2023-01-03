import FeedFeature
import FeedCache
import Foundation

func emptyMoviesPages() -> (model: MoviesPage, cache: CacheMoviesPage) {
    let model = MoviesPage(
        page: 1,
        results: [],
        totalResults: 1,
        totalPages: 1
    )
    let cache = CacheMoviesPage.init(from: model)
    
    return (model, cache)
}

func uniqueMoviesPages() -> (model: MoviesPage, cache: CacheMoviesPage) {
    let model = uniqueMoviesPage()
    let cache = CacheMoviesPage.init(from: model)
    
    return (model, cache)
}

func uniqueMoviesPage() -> MoviesPage {
    let totalPages: Int = .random(in: 1...5)
    let currentPage: Int = .random(in: 1...totalPages)
    
    return MoviesPage(
        page: currentPage,
        results: [uniqueMovie()],
        totalResults: .random(in: 6...10),
        totalPages: totalPages
    )
}

func uniqueMovie() -> Movie {
    Movie(
        id: .random(in: 100000...200000),
        title: "AnyTitle"
    )
}

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}


extension CacheMoviesPage {
    init(from moviesPage: MoviesPage) {
        self.init(
            page: moviesPage.page,
            results: moviesPage.results.map { CacheMovie.init(from: $0) },
            totalResults: moviesPage.totalResults,
            totalPages: moviesPage.totalPages
        )
    }
}

extension CacheMovie {
    init(from movie: Movie) {
        self.init(
            id: movie.id,
            title: movie.title
        )
    }
}

extension Date {
    
    
    func minusFeedCacheMaxAge() -> Date {
        let feedCacheMaxAgeInDays = 7
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}

