//
//  File.swift
//  
//
//  Created by Ted Bennett on 25/10/2020.
//

import Foundation

protocol AppleMusicRelationship: Decodable {
    associatedtype Object
    var data: [Object] { get set }
    var href: URL? { get set }
    var next: URL? { get set }
}

protocol AppleMusicResource: Decodable {
    associatedtype Relationships
    associatedtype Attributes
    
    var relationships: Relationships? { get set }
    var attributes: Attributes? { get set }
    var type: String { get set }
    var href: URL? { get set }
    var id: String { get set }
}


struct AppleMusicResponse<Object: AppleMusicResource>: Decodable {
    var data: [Object]
    var next: URL?
}

struct AppleMusicSearchResponse: Decodable {
    var results: SearchResults
    
    struct SearchResults: Decodable {
        var albums: AppleMusicResponse<AppleMusicAlbum>?
        var artists: AppleMusicResponse<AppleMusicArtist>?
        var playlists: AppleMusicResponse<AppleMusicPlaylist>?
        var songs: AppleMusicResponse<AppleMusicSong>?
    }
    
}
struct AppleMusicSong: AppleMusicResource {
    
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
        var artwork: AppleMusicArtwork
        var composerName: String?
        var contentRating: String?
        var discNumber: Int
        var durationInMillis: Int?
        var editorialNotes: AppleMusicEditorialNotes?
        var genreNames: [String]
        var isrc: String
        var movementCount: Int?
        var movementName: String?
        var movementNumber: Int?
        var name: String
        var playParams: AppleMusicPlayParams?
        var previews: [AppleMusicPreview]
        var releaseDate: String
        var trackNumber: Int
        var url: URL
        var workName: String?
    }
}

struct AppleMusicLibrarySong: AppleMusicResource {
    
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
        var artwork: AppleMusicArtwork
        var contentRating: String?
        var discNumber: Int?
        var durationInMillis: Int?
        var playParams: AppleMusicPlayParams?
        var name: String
        var trackNumber: Int
    }
}

struct AppleMusicAlbum: AppleMusicResource {
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
        var artwork: AppleMusicArtwork?
        var contentRating: String?
        var copyright: String?
        var editorialNotes: AppleMusicEditorialNotes?
        var genreNames: [String]
        var isComplete: Bool
        var isSingle: Bool
        var name: String
        var playParams: AppleMusicPlayParams?
        var recordLabel: String
        var releaseDate: String
        var trackCount: Int
        var url: URL
        var isMasteredForItunes: Bool
    }
}

struct AppleMusicLibraryAlbum: AppleMusicResource {
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
        var artwork: AppleMusicArtwork
        var contentRating: String?
        var name: String
        var playParams: AppleMusicPlayParams?
        var trackCount: Int
    }
}

struct AppleMusicArtist: AppleMusicResource {
    var relationships: Relationships?
    var attributes: Attributes?
    var type: String
    var href: URL?
    var id: String
    
    struct Relationships: Decodable {
        var albums: AlbumRelationship
    }
    
    struct Attributes: Decodable {
        var editorialNotes: AppleMusicEditorialNotes?
        var genreNames: [String]
        var name: String
        var url: URL
    }
}

struct AppleMusicLibraryArtist: AppleMusicResource {
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

struct AppleMusicPlaylist: AppleMusicResource {
    var relationships: Relationships?
    var attributes: Attributes?
    var type: String
    var href: URL?
    var id: String
    
    struct Relationships: Decodable {
        var tracks: SongRelationship
    }
    
    struct Attributes: Decodable {
        var artwork: AppleMusicArtwork?
        var curatorName: String?
        var description: AppleMusicEditorialNotes?
        var lastModifiedDate: String
        var name: String
        var playlistType: String
        var playParams: AppleMusicPlayParams?
        var url: URL
    }
}

struct AppleMusicLibraryPlaylist: AppleMusicResource {
    var relationships: Relationships?
    var attributes: Attributes?
    var type: String
    var href: URL?
    var id: String
    
    struct Relationships: Decodable {
        var tracks: SongRelationship
    }
    
    struct Attributes: Decodable {
        var artwork: AppleMusicArtwork?
        var description: AppleMusicEditorialNotes?
        var name: String
        var playParams: AppleMusicPlayParams?
        var canEdit: Bool
    }
}



struct AppleMusicArtwork: Decodable {
    var bgColor: String?
    var height: Int?
    var width: Int?
    var textColor1: String?
    var textColor2: String?
    var textColor3: String?
    var textColor4: String?
    var url: String
}

struct AppleMusicPreview: Decodable {
    var artwork: AppleMusicArtwork?
    var url: URL
}

struct AppleMusicEditorialNotes: Decodable {
    var short: String?
    var standard: String?
}

struct AppleMusicPlayParams: Decodable {
    var id: String
    var kind: String
    var catalogId: String?
    var globalId: String?
    var isLibrary: Bool?
}



struct SongRelationship: AppleMusicRelationship {
    var data: [AppleMusicSong]
    var href: URL?
    var next: URL?
}

struct LibrarySongRelationship: AppleMusicRelationship {
    var data: [AppleMusicLibrarySong]
    var href: URL?
    var next: URL?
}

struct AlbumRelationship: AppleMusicRelationship {
    var data: [AppleMusicAlbum]
    var href: URL?
    var next: URL?
}

struct LibraryAlbumRelationship: AppleMusicRelationship {
    var data: [AppleMusicLibraryAlbum]
    var href: URL?
    var next: URL?
}

struct ArtistRelationship: AppleMusicRelationship {
    var data: [AppleMusicArtist]
    var href: URL?
    var next: URL?
}

struct LibraryArtistRelationship: AppleMusicRelationship {
    var data: [AppleMusicLibraryArtist]
    var href: URL?
    var next: URL?
}
