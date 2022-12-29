import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Error) -> Void)
}

public final class RemoteFeedLoader {
    
    public enum Error: Swift.Error {
        case connectivity
    }
    
    // MARK: - Private Properties
    
    private let url: URL
    private let client: HTTPClient
    
    // MARK: - Init
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    // MARK: - API
    
    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}
