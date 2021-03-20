import Foundation

public class AppleMusicAPI {
    public static let manager = AppleMusicAPI()
    
    private init() {}
    
    private var developerToken: String?
    private var userToken: String?
    private var storefront: String?
    
    public func initialize(developerToken: String, userToken: String) {
        self.developerToken = developerToken
        self.userToken = userToken
        getUserStorefront { storefront, error in
            guard let id = storefront?.first?.id else {
                print(error.debugDescription)
                self.storefront = "gb"
                return
            }
            self.storefront = id
        }
    }
    
    public func initialize(developerToken: String) {
        self.developerToken = developerToken
        storefront = "gb"
    }
    
    public func isInialized() -> Bool {
        return developerToken != nil
    }
    
    public func hasUserAccess() -> Bool {
        return developerToken != nil && userToken != nil
    }
}

// MARK: - Requests

extension AppleMusicAPI {
    private func request<ResponseType: AppleMusicResponse>(url: URLRequest, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 429 {
                    let retryDelay = 1.0 // Apple API doesn't provide a retry after, so we have to guess
                    DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
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
                if let response = response as? HTTPURLResponse {
                    print(response.statusCode)
                }
                completion(nil, parseError)
            }
        }.resume()
    }
    
    private func requestWithNoResponseBody(url: URLRequest, completion: @escaping (Bool, Error?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                    case 429:
                        if let retryDelay = response.value(forHTTPHeaderField: "Retry-After") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryDelay)!) {
                                self.requestWithNoResponseBody(url: url, completion: completion)
                            }
                            return
                        }
                    case 204, 202, 200:
                        completion(true, nil)
                    default:
                        if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                            print(json)
                        }
                        completion(false, error)
                }
                
            } else {
                completion(false, error)
            }
        }.resume()
    }
    
    private func arrayRequest<Object: AppleMusicResource>(url: URLRequest, requiresUserAccess: Bool = true, completion: @escaping ([Object]?, Error?) -> Void) {
        let arrayCompletion: (Response<Object>?, Error?) -> Void = { response, error in
            if let responseObjects = response?.data {
            
                if let next = response?.next, let nextUrl = URL(string: baseUrl + next)  {
                    self.arrayRequest(url: self.getAuthenticatedUrl(url: nextUrl, method: .get, requiresUserAccess: requiresUserAccess)) { (objects: [Object]?, error) in
                        guard let paginatedObjects = objects else {
                            completion(objects, error)
                            return
                        }
                        guard error == nil else {
                            completion(objects, error)
                            return
                        }
                        let newObjects = responseObjects.compactMap { $0.value } + paginatedObjects
                        completion(newObjects, nil)
                    }
                } else {
                    completion(responseObjects.compactMap { $0.value }, error)
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
    private func getUrlRequest(for paths: [String], method: HTTPMethod = .get, queries: [String:String] = [:], requiresUserAccess: Bool = true) throws -> URLRequest  {
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
        
        return getAuthenticatedUrl(url: url, method: method, requiresUserAccess: requiresUserAccess)
    }
    
    private func getAuthenticatedUrl(url: URL, method: HTTPMethod, requiresUserAccess: Bool) -> URLRequest {
        guard isInialized() else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        if requiresUserAccess && userToken == nil {
            fatalError("Apple Music manager not initialized with user access, call initialize() before use")
        }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(developerToken!)", forHTTPHeaderField: "Authorization")
        if requiresUserAccess {
            request.addValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        }

        request.httpMethod = method.rawValue
        return request
    }
    
    private func getRequestBody<Body: Codable>(body: Body) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(body)
    }
}

// MARK: - Storefront

extension AppleMusicAPI {
    
    func getUserStorefront(completion: @escaping ([Storefront]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.storefront]])
        if let url = url {
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
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
    
    public func getLibraryPlaylistSongs(id: String, completion: @escaping ([LibrarySong]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.playlists], id, Endpoint[.tracks]])
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
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.playlists], id], requiresUserAccess: false)
        if let url = url {
            arrayRequest(url: url, requiresUserAccess: false, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogPlaylistSongs(id: String, completion: @escaping ([Song]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.playlists], id, Endpoint[.tracks]], requiresUserAccess: false)
        if let url = url {
            arrayRequest(url: url, requiresUserAccess: false, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func createLibraryPlaylist(name: String, description: String?, songs: [Song], librarySongs: [LibrarySong], completion: @escaping ([LibraryPlaylist]?, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.playlists]], method: .post)
        
        let tracks = songs.map { LibraryPlaylistRequestTrack(id: $0.id, type: "songs") } + librarySongs.map { LibraryPlaylistRequestTrack(id: $0.id, type: "library-songs") }
        let body = LibraryPlaylistRequest(name: name, description: description, tracks: tracks)
        
        
        if var url = url {
            if let data = getRequestBody(body: body) {
                url.httpBody = data
            }
            arrayRequest(url: url, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func addTracksToLibraryPlaylist(id: String, songs: [Song], librarySongs: [LibrarySong], completion: @escaping (Bool, Error?) -> Void) {
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.playlists], id, Endpoint[.tracks]], method: .post)
        
        let tracks = songs.map { LibraryPlaylistRequestTrack(id: $0.id, type: "songs") } + librarySongs.map { LibraryPlaylistRequestTrack(id: $0.id, type: "library-songs") }
        let body = LibraryPlaylistTracksRequest(data: tracks)
        
        if var url = url {
            if let data = getRequestBody(body: body) {
                url.httpBody = data
            }
            requestWithNoResponseBody(url: url, completion: completion)
        } else {
            completion(false, ApiError.invalidUrl)
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
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.albums], id], requiresUserAccess: false)
        if let url = url {
            arrayRequest(url: url, requiresUserAccess: false, completion: completion)
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
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.artists], id], requiresUserAccess: false)
        if let url = url {
            arrayRequest(url: url, requiresUserAccess: false, completion: completion)
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
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.songs], id], requiresUserAccess: false)
        if let url = url {
            arrayRequest(url: url, requiresUserAccess: false, completion: completion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getCatalogSongByIsrcId(isrcId: String, completion: @escaping (Song?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.songs]], queries: ["filter[isrc]": isrcId], requiresUserAccess: false)
        if let url = url {
            let wrappedCompletion: ([Song]?, Error?) -> Void = {songs, error in
                if let songs = songs {
                    completion(songs.first, nil)
                } else {
                    completion(nil, error)
                }
            }
            arrayRequest(url: url, requiresUserAccess: false, completion: wrappedCompletion)
        } else {
            completion(nil, ApiError.invalidUrl)
        }
    }
    
    public func getLibrarySongIsrcId(song: LibrarySong, completion: @escaping (String?, Error?) -> Void) {
        if let attributes = song.attributes {
            let terms = "\(attributes.name) \(attributes.artistName)"
            searchCatalogSongs(term: terms) { songs, error in
                if let songs = songs {
                    completion(songs.first?.attributes?.isrc, nil)
                } else {
                    completion(nil, error)
                }
            }
        }
    }
}

// MARK: - Search

extension AppleMusicAPI {
    public func searchCatalog(term: String, searchTypes: [SearchType] = [], completion: @escaping ([Song]?, [Album]?, [Artist]?, [Playlist]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        var queries = ["term": term.replacingOccurrences(of: " ", with: "+")]
        if !searchTypes.isEmpty {
            queries["types"] = searchTypes.map { $0.rawValue }.joined(separator: ",")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.catalog], storefront!, Endpoint[.search]], queries: queries, requiresUserAccess: false)
        
        if let url = url {
            let searchCompletion: (SearchResponse?, Error?) -> Void = { response, error in
                if let results = response?.results {
                    completion(results.songs?.data.compactMap { $0.value }, results.albums?.data.compactMap { $0.value }, results.artists?.data.compactMap { $0.value }, results.playlists?.data.compactMap { $0.value }, error)
                } else {
                    completion(nil, nil, nil, nil, error)
                }
            }
            request(url: url, completion: searchCompletion)
        } else {
            completion(nil, nil, nil, nil, ApiError.invalidUrl)
        }
    }
    
    public func searchCatalogSongs(term: String, completion: @escaping ([Song]?, Error?) -> Void) {
        let songCompletion: ([Song]?, [Album]?, [Artist]?, [Playlist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(songs, error)
        }
        searchCatalog(term: term, searchTypes: [.songs], completion: songCompletion)
    }
        
    public func searchCatalogAlbums(term: String, completion: @escaping ([Album]?, Error?) -> Void) {
        let albumCompletion: ([Song]?, [Album]?, [Artist]?, [Playlist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(albums, error)
        }
        searchCatalog(term: term, searchTypes: [.albums], completion: albumCompletion)
    }
    
    public func searchCatalogArtists(term: String, completion: @escaping ([Artist]?, Error?) -> Void) {
        let artistCompletion: ([Song]?, [Album]?, [Artist]?, [Playlist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(artists, error)
        }
        searchCatalog(term: term, searchTypes: [.artists], completion: artistCompletion)
    }
    
    public func searchCatalogPlaylists(term: String, completion: @escaping ([Playlist]?, Error?) -> Void) {
        let playlistCompletion: ([Song]?, [Album]?, [Artist]?, [Playlist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(playlists, error)
        }
        searchCatalog(term: term, searchTypes: [.playlists], completion: playlistCompletion)
    }
    
    public func searchLibrary(term: String, searchTypes: [SearchType] = [], completion: @escaping ([LibrarySong]?, [LibraryAlbum]?, [LibraryArtist]?, [LibraryPlaylist]?, Error?) -> Void) {
        guard storefront != nil else {
            fatalError("Apple Music manager not initialized, call initialize() before use")
        }
        var queries = ["term": term.replacingOccurrences(of: " ", with: "+")]
        if !searchTypes.isEmpty {
            queries["types"] = searchTypes.map { $0.rawValue }.joined(separator: ",")
        }
        let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library], Endpoint[.search]], queries: queries)
        
        if let url = url {
            let searchCompletion: (LibrarySearchResponse?, Error?) -> Void = { response, error in
                if let results = response?.results {
                    completion(results.librarySongs?.data.compactMap { $0.value }, results.libraryAlbums?.data.compactMap { $0.value }, results.libraryArtists?.data.compactMap { $0.value }, results.libraryPlaylists?.data.compactMap { $0.value }, error)
                } else {
                    completion(nil, nil, nil, nil, error)
                }
            }
            request(url: url, completion: searchCompletion)
        } else {
            completion(nil, nil, nil, nil, ApiError.invalidUrl)
        }
    }
    
    public func searchLibrarySongs(term: String, completion: @escaping ([LibrarySong]?, Error?) -> Void) {
        let songCompletion: ([LibrarySong]?, [LibraryAlbum]?, [LibraryArtist]?, [LibraryPlaylist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(songs, error)
        }
        searchLibrary(term: term, searchTypes: [.librarySongs], completion: songCompletion)
    }
    
    public func searchLibraryAlbums(term: String, completion: @escaping ([LibraryAlbum]?, Error?) -> Void) {
        let albumCompletion: ([LibrarySong]?, [LibraryAlbum]?, [LibraryArtist]?, [LibraryPlaylist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(albums, error)
        }
        searchLibrary(term: term, searchTypes: [.libraryAlbums], completion: albumCompletion)
    }
    
    public func searchLibraryArtists(term: String, completion: @escaping ([LibraryArtist]?, Error?) -> Void) {
        let artistCompletion: ([LibrarySong]?, [LibraryAlbum]?, [LibraryArtist]?, [LibraryPlaylist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(artists, error)
        }
        searchLibrary(term: term, searchTypes: [.libraryArtists], completion: artistCompletion)
    }
    
    public func searchLibraryPlaylists(term: String, completion: @escaping ([LibraryPlaylist]?, Error?) -> Void) {
        let playlistCompletion: ([LibrarySong]?, [LibraryAlbum]?, [LibraryArtist]?, [LibraryPlaylist]?, Error?) -> Void = { songs, albums, artists, playlists, error in
            completion(playlists, error)
        }
        searchLibrary(term: term, searchTypes: [.libraryPlaylists], completion: playlistCompletion)
    }
}

// MARK: Library

extension AppleMusicAPI {
    func addResourceToLibrary(songs: [String], albums: [String], playlists: [String], completion: @escaping (Bool, Error?) -> Void) {
        
        let queries = [
            "ids[songs]": songs.joined(separator: ","),
            "ids[albums]": albums.joined(separator: ","),
            "ids[playlists]": playlists.joined(separator: ",")
        ]
        
        
        guard let url = try? getUrlRequest(for: [Endpoint[.version], Endpoint[.me], Endpoint[.library]], method: .post, queries: queries) else {
            completion(false, ApiError.invalidUrl)
            return
        }
        
        requestWithNoResponseBody(url: url, completion: completion)
    }
    
    func addResourceToLibrary(songs: [Song], albums: [Album], playlists: [Playlist], completion: @escaping (Bool, Error?) -> Void) {
        addResourceToLibrary(songs: songs.map { $0.id }, albums: albums.map { $0.id }, playlists: playlists.map { $0.id }, completion: completion)
    }
    
    public func addSongsToLibrary(songs: [String], completion: @escaping (Bool, Error?) -> Void) {
        addResourceToLibrary(songs: songs, albums: [], playlists: [], completion: completion)
    }
    
    public func addAlbumsToLibrary(albums: [String], completion: @escaping (Bool, Error?) -> Void) {
        addResourceToLibrary(songs: [], albums: albums, playlists: [], completion: completion)
    }
    
    public func addPlaylistsToLibrary(playlists: [String], completion: @escaping (Bool, Error?) -> Void) {
        addResourceToLibrary(songs: [], albums: [], playlists: playlists, completion: completion)
    }
}
