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
    private func request<ResponseType: AppleMusicResponse>(url: URLRequest, completion: @escaping (ResponseType?, Error?) -> Void) {
        
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
                let decoded = try decoder.decode(ResponseType.self, from: data)
                
                // more pages of data
                completion(decoded, nil)
            } catch let parseError {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    print(json)
                }
                completion(nil, parseError)
            }
        }.resume()
    }
    
    private func arrayRequest<Object: AppleMusicResource>(url: URLRequest, completion: @escaping ([Object]?, Error?) -> Void) {
        let arrayCompletion: (Response<Object>?, Error?) -> Void = { response, error in
            if let responseObjects = response?.data {
            
                if let next = response?.next, let nextUrl = URL(string: baseUrl + next)  {
                    self.arrayRequest(url: self.getAuthenticatedUrl(url: nextUrl, method: .get)) { (objects: [Object]?, error) in
                        guard let paginatedObjects = objects else {
                            completion(objects, error)
                            return
                        }
                        guard error == nil else {
                            completion(objects, error)
                            return
                        }
                        let newObjects = responseObjects + paginatedObjects
                        completion(newObjects, nil)
                    }
                } else {
                    completion(responseObjects, error)
                }
            } else {
                completion(nil, error)
            }
        }
        request(url: url, completion: arrayCompletion)
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
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getLibraryPlaylist(id: String, completion: @escaping ([LibraryPlaylist]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.playlists], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogPlaylist(id: String, completion: @escaping ([Playlist]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.playlists], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
}

// MARK: - Albums

extension AppleMusicAPI {
    
    public func getAllLibraryAlbums(completion: @escaping ([LibraryAlbum]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.albums]])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getLibraryAlbum(id: String, completion: @escaping ([LibraryAlbum]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.albums], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogAlbum(id: String, completion: @escaping ([Album]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.albums], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
}

// MARK: - Artists

extension AppleMusicAPI {
    
    public func getAllLibraryArtists(completion: @escaping ([LibraryArtist]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.artists]])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getLibraryArtist(id: String, completion: @escaping ([LibraryArtist]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.artists], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogArtist(id: String, completion: @escaping ([Artist]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.artists], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
}

// MARK: - Songs

extension AppleMusicAPI {
    
    public func getAllLibrarySongs(completion: @escaping ([LibrarySong]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.songs]])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getLibrarySong(id: String, completion: @escaping ([LibrarySong]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.songs], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogSong(id: String, completion: @escaping ([Song]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.songs], id])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
}

// MARK: - Search

extension AppleMusicAPI {
    public func searchCatalog(term: String, completion: @escaping ([Song]?, [Album]?, [Artist]?, [Playlist]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.search]], queries: ["term": term.replacingOccurrences(of: " ", with: "+")])
        
        if let url = url {
            let searchCompletion: (SearchResponse?, Error?) -> Void = { response, error in
                if let results = response?.results {
                    completion(results.songs?.data, results.albums?.data, results.artists?.data, results.playlists?.data, error)
                } else {
                    completion(nil, nil, nil, nil, error)
                }
            }
            request(url: url, completion: searchCompletion)
            
        } else {
            completion(nil, nil, nil, nil, ApiError.invalidUrl)
        }
    }
}
