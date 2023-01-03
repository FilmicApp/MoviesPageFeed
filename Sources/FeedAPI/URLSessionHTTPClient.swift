import Foundation

public class URLSessionHTTPClient: HTTPClient {
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    // MARK: - Private Properties
    
    private let session: URLSession
    
    // MARK: - Init
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - API
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
