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
    private func request<Object: AppleMusicResource>(url: URLRequest, completion: @escaping ([Object]?, Error?) -> Void) {
        
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
                let decoded = try decoder.decode(Response<Object>.self, from: data)
                
                // more pages of data
                if let next = decoded.next  {
                    let nextUrl = URL(string: baseUrl)!.appendingPathComponent(next)
                    self.request(url: self.getAuthenticatedUrl(url: nextUrl, method: .get)) { (objects: [Object]?, error) in
                        guard let paginatedObjects = objects else {
                            completion(objects, error)
                            return
                        }
                        guard error == nil else {
                            completion(objects, error)
                            return
                        }
                        var newObjects = decoded.data
                        newObjects.append(contentsOf: paginatedObjects)
                        completion(newObjects, nil)
                    }
                } else {
                    completion(decoded.data, nil)
                }
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
    private func getUrlRequest(for paths: [String], method: HTTPMethod = .get, queries: [String:String] = [:]) throws -> URLRequest  {
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
    
    private func getAuthenticatedUrl(url: URL, method: HTTPMethod) -> URLRequest {
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

// MARK: - Playlists

extension AppleMusicAPI {
    
    public func getAllLibraryPlaylists(completion: @escaping ([LibraryPlaylist]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.playlists]])
        if let url = url {
            request(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getLibraryPlaylist(id: String, completion: @escaping ([LibraryPlaylist]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.playlists], id])
        if let url = url {
            request(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogPlaylist(id: String, completion: @escaping ([LibraryPlaylist]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.playlists], id])
        if let url = url {
            request(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
}
