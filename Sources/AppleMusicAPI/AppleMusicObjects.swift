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
    var next: String? { get set }
}

public protocol AppleMusicResource: Decodable, Identifiable {
    associatedtype Relationships
    associatedtype Attributes
    
    var relationships: Relationships? { get set }
    var attributes: Attributes? { get set }
    var type: String { get set }
    var href: URL? { get set }
    var id: String { get set }
}

public protocol AppleMusicResponse: Decodable {

}

extension AppleMusicAPI {
    
    struct Response<Object: AppleMusicResource>: AppleMusicResponse {
        var data: [Object]
        var next: String?
    }
    
    struct SearchResponse: AppleMusicResponse {
        var results: SearchResults
        
        struct SearchResults: Decodable {
            var albums: Response<Album>?
            var artists: Response<Artist>?
            var playlists: Response<Playlist>?
            var songs: Response<Song>?
        }
    }
    
    struct LibrarySearchResponse: AppleMusicResponse {
        var results: SearchResults
        
        struct SearchResults: Decodable {
            var albums: Response<LibraryAlbum>?
            var artists: Response<LibraryArtist>?
            var playlists: Response<LibraryPlaylist>?
            var songs: Response<LibrarySong>?
        }
    }
    
    public struct Song: AppleMusicResource {
        
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var albums: AlbumRelationship?
            public var artists: ArtistRelationship?
        }
        
        public struct Attributes: Decodable {
            public var albumName: String
            public var artistName: String
            public var artwork: Artwork
            public var composerName: String?
            public var contentRating: String?
            public var discNumber: Int
            public var durationInMillis: Int?
            public var editorialNotes: EditorialNotes?
            public var genreNames: [String]
            public var isrc: String
            public var movementCount: Int?
            public var movementName: String?
            public var movementNumber: Int?
            public var name: String
            public var playParams: PlayParams?
            public var previews: [Preview]
            public var releaseDate: String
            public var trackNumber: Int
            public var url: URL
            public var workName: String?
        }
    }
    
    public struct LibrarySong: AppleMusicResource {
        
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var albums: LibraryAlbumRelationship?
            public var artists: LibraryArtistRelationship?
        }
        
        public struct Attributes: Decodable {
            public var albumName: String
            public var artistName: String
            public var artwork: Artwork
            public var contentRating: String?
            public var discNumber: Int?
            public var durationInMillis: Int?
            public var playParams: PlayParams?
            public var name: String
            public var trackNumber: Int
        }
    }
    
    public struct Album: AppleMusicResource {
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var tracks: SongRelationship
            public var artist: ArtistRelationship
        }
        
        public struct Attributes: Decodable {
            public var albumName: String
            public var artistName: String
            public var artwork: Artwork?
            public var contentRating: String?
            public var copyright: String?
            public var editorialNotes: EditorialNotes?
            public var genreNames: [String]
            public var isComplete: Bool
            public var isSingle: Bool
            public var name: String
            public var playParams: PlayParams?
            public var recordLabel: String
            public var releaseDate: String
            public var trackCount: Int
            public var url: URL
            public var isMasteredForItunes: Bool
        }
    }
    
    public struct LibraryAlbum: AppleMusicResource {
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var tracks: LibrarySongRelationship
            public var artist: LibraryArtistRelationship
        }
        
        public struct Attributes: Decodable {
            public var artistName: String
            public var artwork: Artwork
            public var contentRating: String?
            public var name: String
            public var playParams: PlayParams?
            public var trackCount: Int
        }
    }
    
    public struct Artist: AppleMusicResource {
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var albums: AlbumRelationship
        }
        
        public struct Attributes: Decodable {
            public var editorialNotes: EditorialNotes?
            public var genreNames: [String]
            public var name: String
            public var url: URL
        }
    }
    
    public struct LibraryArtist: AppleMusicResource {
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var albums: LibraryAlbumRelationship
        }
        
        public struct Attributes: Decodable {
            public var name: String
        }
    }
    
    public struct Playlist: AppleMusicResource {
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var tracks: SongRelationship
        }
        
        public struct Attributes: Decodable {
            public var artwork: Artwork?
            public var curatorName: String?
            public var description: EditorialNotes?
            public var lastModifiedDate: String
            public var name: String
            public var playlistType: String
            public var playParams: PlayParams?
            public var url: URL
        }
    }
    
    public struct LibraryPlaylist: AppleMusicResource {
        public var relationships: Relationships?
        public var attributes: Attributes?
        public var type: String
        public var href: URL?
        public var id: String
        
        public struct Relationships: Decodable {
            public var tracks: SongRelationship
        }
        
        public struct Attributes: Decodable {
            public var artwork: Artwork?
            public var description: EditorialNotes?
            public var name: String
            public var playParams: PlayParams?
            public var canEdit: Bool
        }
    }
    
    
    
    public struct Artwork: Decodable {
        public var bgColor: String?
        public var height: Int?
        public var width: Int?
        public var textColor1: String?
        public var textColor2: String?
        public var textColor3: String?
        public var textColor4: String?
        public var url: String
    }
    
    public struct Preview: Decodable {
        public var artwork: Artwork?
        public var url: URL
    }
    
    public struct EditorialNotes: Decodable {
        public var short: String?
        public var standard: String?
    }
    
    public struct PlayParams: Decodable {
        public var id: String
        public var kind: String
        public var catalogId: String?
        public var globalId: String?
        public var isLibrary: Bool?
    }
    
    
    
    public struct SongRelationship: AppleMusicRelationship {
        public var data: [Song]
        public var href: URL?
        public var next: String?
    }
    
    public struct LibrarySongRelationship: AppleMusicRelationship {
        public var data: [LibrarySong]
        public var href: URL?
        public var next: String?
    }
    
    public struct AlbumRelationship: AppleMusicRelationship {
        public var data: [Album]
        public var href: URL?
        public var next: String?
    }
    
    public struct LibraryAlbumRelationship: AppleMusicRelationship {
        public var data: [LibraryAlbum]
        public var href: URL?
        public var next: String?
    }
    
    public struct ArtistRelationship: AppleMusicRelationship {
        public var data: [Artist]
        public var href: URL?
        public var next: String?
    }
    
    public struct LibraryArtistRelationship: AppleMusicRelationship {
        public var data: [LibraryArtist]
        public var href: URL?
        public var next: String?
    }
}
