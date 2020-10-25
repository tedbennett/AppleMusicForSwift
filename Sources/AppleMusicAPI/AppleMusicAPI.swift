import Foundation

public class AppleMusicAPI {
    public static let manager = AppleMusicAPI()
    
    private init() {}
    
    private var developerToken: String?
    private var userToken: String?
    private var storefront: String?
    
    public func initialize(developerToken: String, userToken: String, storefront: String) {
        self.developerToken = developerToken
        self.userToken = userToken
        self.storefront = storefront
    }
}

// MARK: - Requests

extension AppleMusicAPI {
    private func request<Object: Decodable>(url: URLRequest, completion: @escaping (Object?, Error?) -> Void) {
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 429, let retryDelay = response.value(forHTTPHeaderField: "Retry-After") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryDelay)!) {
                        self.request(url: url, completion: completion)
                    }
                    return
                }
            }
            
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "No data returned", code: 10, userInfo: nil))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let decoded = try decoder.decode(Object.self, from: data)
                completion(decoded, nil)
            } catch let parseError {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print(json)
                }
                completion(nil, parseError)
            }
        }.resume()
    }
}

// MARK: - URL Handling

extension AppleMusicAPI {
    func getUrlRequest(for paths: [String], method: HTTPMethod = .get, queries: [String:String] = [:]) throws -> URLRequest  {
        var components = URLComponents(string: baseUrl)!
        components.queryItems = queries.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        guard var url = components.url else {
            throw ApiError.invalidUrl
        }
        
        paths.forEach { path in
            url.appendPathComponent(path)
        }
        
        return getAuthenticatedUrl(url: url, method: method)
    }
    
    func getAuthenticatedUrl(url: URL, method: HTTPMethod) -> URLRequest {
        guard developerToken != nil, userToken != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(developerToken!)", forHTTPHeaderField: "Authorization")
        request.addValue(userToken!, forHTTPHeaderField: "Music-User-Token")

        request.httpMethod = method.rawValue
        return request
    }
}
