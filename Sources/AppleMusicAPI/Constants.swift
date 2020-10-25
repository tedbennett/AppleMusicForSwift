//
//  File.swift
//  
//
//  Created by Ted Bennett on 25/10/2020.
//

import Foundation

var baseUrl = "https://api.music.apple.com/"

enum Endpoint: String {
    case version = "v1"
    case me = "me"
    case library = "library"
    case catalog = "catalog"
    case storefront = "storefront"
    case playlists = "playlists"
    case tracks = "tracks"
    case albums = "albums"
    case songs = "songs"
    case search = "search"
    
    static subscript(_ endpoint: Endpoint) -> String {
        return endpoint.rawValue
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum ApiError: Error {
    case invalidUrl
    case invalidAccessToken
    case invalidSearchObject
    case resourceDoesNotExist
    case expiredAccessToken
    case tooManyRequests
}
