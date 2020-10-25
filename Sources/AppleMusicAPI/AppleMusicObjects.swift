//
//  File.swift
//  
//
//  Created by Ted Bennett on 25/10/2020.
//

import Foundation



public protocol AppleMusicRelationship: Decodable {
    associatedtype Object
    var data: [Object] { get set }
    var href: URL? { get set }
    var next: URL? { get set }
}

public protocol AppleMusicResource: Decodable {
    associatedtype Relationships
    associatedtype Attributes
    
    var relationships: Relationships? { get set }
    var attributes: Attributes? { get set }
    var type: String { get set }
    var href: URL? { get set }
    var id: String { get set }
}
extension AppleMusicAPI {
    
    public struct Response<Object: AppleMusicResource>: Decodable {
        var data: [Object]
        var next: URL?
    }
    
    struct SearchResponse: Decodable {
        var results: SearchResults
        
        struct SearchResults: Decodable {
            var albums: Response<Album>?
            var artists: Response<Artist>?
            var playlists: Response<Playlist>?
            var songs: Response<Song>?
        }
        
    }
    struct Song: AppleMusicResource {
        
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var albums: AlbumRelationship?
            var artists: ArtistRelationship?
        }
        
        struct Attributes: Decodable {
            var albumName: String
            var artistName: String
            var artwork: Artwork
            var composerName: String?
            var contentRating: String?
            var discNumber: Int
            var durationInMillis: Int?
            var editorialNotes: EditorialNotes?
            var genreNames: [String]
            var isrc: String
            var movementCount: Int?
            var movementName: String?
            var movementNumber: Int?
            var name: String
            var playParams: PlayParams?
            var previews: [Preview]
            var releaseDate: String
            var trackNumber: Int
            var url: URL
            var workName: String?
        }
    }
    
    struct LibrarySong: AppleMusicResource {
        
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var albums: LibraryAlbumRelationship?
            var artists: LibraryArtistRelationship?
        }
        
        struct Attributes: Decodable {
            var albumName: String
            var artistName: String
            var artwork: Artwork
            var contentRating: String?
            var discNumber: Int?
            var durationInMillis: Int?
            var playParams: PlayParams?
            var name: String
            var trackNumber: Int
        }
    }
    
    struct Album: AppleMusicResource {
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var tracks: SongRelationship
            var artist: ArtistRelationship
        }
        
        struct Attributes: Decodable {
            var albumName: String
            var artistName: String
            var artwork: Artwork?
            var contentRating: String?
            var copyright: String?
            var editorialNotes: EditorialNotes?
            var genreNames: [String]
            var isComplete: Bool
            var isSingle: Bool
            var name: String
            var playParams: PlayParams?
            var recordLabel: String
            var releaseDate: String
            var trackCount: Int
            var url: URL
            var isMasteredForItunes: Bool
        }
    }
    
    struct LibraryAlbum: AppleMusicResource {
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var tracks: LibrarySongRelationship
            var artist: LibraryArtistRelationship
        }
        
        struct Attributes: Decodable {
            var artistName: String
            var artwork: Artwork
            var contentRating: String?
            var name: String
            var playParams: PlayParams?
            var trackCount: Int
        }
    }
    
    struct Artist: AppleMusicResource {
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var albums: AlbumRelationship
        }
        
        struct Attributes: Decodable {
            var editorialNotes: EditorialNotes?
            var genreNames: [String]
            var name: String
            var url: URL
        }
    }
    
    struct LibraryArtist: AppleMusicResource {
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var albums: LibraryAlbumRelationship
        }
        
        struct Attributes: Decodable {
            var name: String
        }
    }
    
    struct Playlist: AppleMusicResource {
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var tracks: SongRelationship
        }
        
        struct Attributes: Decodable {
            var artwork: Artwork?
            var curatorName: String?
            var description: EditorialNotes?
            var lastModifiedDate: String
            var name: String
            var playlistType: String
            var playParams: PlayParams?
            var url: URL
        }
    }
    
    struct LibraryPlaylist: AppleMusicResource {
        var relationships: Relationships?
        var attributes: Attributes?
        var type: String
        var href: URL?
        var id: String
        
        struct Relationships: Decodable {
            var tracks: SongRelationship
        }
        
        struct Attributes: Decodable {
            var artwork: Artwork?
            var description: EditorialNotes?
            var name: String
            var playParams: PlayParams?
            var canEdit: Bool
        }
    }
    
    
    
    struct Artwork: Decodable {
        var bgColor: String?
        var height: Int?
        var width: Int?
        var textColor1: String?
        var textColor2: String?
        var textColor3: String?
        var textColor4: String?
        var url: String
    }
    
    struct Preview: Decodable {
        var artwork: Artwork?
        var url: URL
    }
    
    struct EditorialNotes: Decodable {
        var short: String?
        var standard: String?
    }
    
    struct PlayParams: Decodable {
        var id: String
        var kind: String
        var catalogId: String?
        var globalId: String?
        var isLibrary: Bool?
    }
    
    
    
    struct SongRelationship: AppleMusicRelationship {
        var data: [Song]
        var href: URL?
        var next: URL?
    }
    
    struct LibrarySongRelationship: AppleMusicRelationship {
        var data: [LibrarySong]
        var href: URL?
        var next: URL?
    }
    
    struct AlbumRelationship: AppleMusicRelationship {
        var data: [Album]
        var href: URL?
        var next: URL?
    }
    
    struct LibraryAlbumRelationship: AppleMusicRelationship {
        var data: [LibraryAlbum]
        var href: URL?
        var next: URL?
    }
    
    struct ArtistRelationship: AppleMusicRelationship {
        var data: [Artist]
        var href: URL?
        var next: URL?
    }
    
    struct LibraryArtistRelationship: AppleMusicRelationship {
        var data: [LibraryArtist]
        var href: URL?
        var next: URL?
    }
}
