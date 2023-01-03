import Foundation

final class FeedCachePolicy {
    
    // MARK: - Private Properties
    
    private static let calendar = Calendar(identifier: .gregorian)

    private static var maxCacheAgeInDays = 7
    
    // MARK: - Init
    
    private init() {}
        
    // MARK: - API
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return date < maxCacheAge
    }
}
