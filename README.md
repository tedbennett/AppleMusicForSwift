# AppleMusicAPI

Wrapper for Apple Music API

## Description

This is a package to make interacting with the Apple Music API a lot easier. I decided to make this after finding difficulties working with the Spotify and Apple Music APIs in another project. I created the Spotify for Swift package (still WIP), and decided to create an Apple Music one too.

So far, this package can perform the most common interactions with the API. I haven't handled things like Stations, Recommendations and Charts, but they will be implemented in the future.

My primary aim for this package was to use it in an app to transfer playlists between Apple Music and Spotify. There's a few functions that help to do this. The basic flow here is:

Get AM Library Playlist tracks -> Search for Catalog version of each track -> Get ISRC ID from Catalog -> Search on Spotify for each ISRC ID to get each Spotify URI -> Create Spotify playlist

The reverse process is simpler:

Get Spotify Playlist tracks -> Get ISRC ID for each track -> Get each track on AM by ISRC ID -> Create AM Playlist

Due to having to search for each individual track's Catalog version or ISRC number, the Too Many Requests error is frequently hit (this package can retry the request in that case).

## Usage

You'll need to be part of the Apple Developer program to access this API. At the moment, you need both your developer token and the user's MusicKit token. You can obtain this using:

    import StoreKit

    class AppleMusicManager {

        var controller = SKCloudServiceController()

        func getAppleMusicAuth() {
            SKCloudServiceController.requestAuthorization { status in
                if status == .authorized {
                    self.controller.requestCapabilities { capabilities, error in
                        if capabilities.contains(.addToCloudMusicLibrary) {
                            self.controller.requestUserToken(forDeveloperToken: self.developerToken) { userToken, error in
                                
                                // Do something with the userToken

                            }
                        }
                    }
                }
            }
        }
    }


API Endpoint | Implemented? | Notes
--- | :---: | ---:
Add a resource to a Library | ✅ |
Get a Catalog song | ✅ |
Get a Catalog song's artists | ❌ |
Get multiple Catalog songs | ❌ |
Get multiple Catalog songs by ISRC | ❌ |
Get a Library song | ✅ |
Get a Library song's artists | ✅ |
Get multiple Library songs | ❌ |
Get all Library songs | ✅ |
Get a Catalog album | ✅ |
Get a Catalog album's songs | ❌ |
Get multiple Catalog albums | ❌ |
Get a Library album | ✅ |
Get a Library album's songs | ❌ |
Get multiple Library albums | ❌ |
Get all Library albums | ✅ |
Get a Catalog artist | ✅ |
Get a Catalog artist's songs | ✅ |
Get a Catalog artist's albums | ❌ |
Get multiple Catalog artists | ❌ |
Get a Library artist | ✅ |
Get a Library artist's songs | ✅ |
Get a Library artist's albums | ❌ |
Get multiple Library artists | ❌ |
Get all Library artists | ✅ |
Get a Catalog playlist | ✅ |
Get a Catalog playlist's songs | ✅ |
Get a Catalog playlist's albums | ❌ |
Get multiple Catalog playlists | ❌ |
Get a Library playlist | ✅ |
Get a Library playlist's songs | ✅ |
Get a Library playlist's albums | ❌ |
Get multiple Library playlists | ❌ |
Get all Library playlists | ✅ |
Create a new playlist | ✅ |
Add tracks to a playlist | ✅ |
Search Catalog | ✅ |
Search Catalog for songs | ✅ |
Search Catalog for albums | ✅ |
Search Catalog for artists | ✅ |
Search Catalog for playlists | ✅ |
Search Library | ✅ |
Search Library for songs | ✅ |
Search Library for albums | ✅ |
Search Library for artists | ✅ |
Search Library for playlists | ✅ |
Get Catalog Search Hints | ❌ |
Get Heavy Rotation Content | ❌ |
Get Recently Played Resources | ❌ |
Get Recently Played Stations | ❌ |
Get Recently Added Resources | ❌ |
Get a Catalog Activity | ❌ |
Get a Catalog Activity's Relationship Directly by Name | ❌ |
Get Multiple Catalog Activities | ❌ |
Get a Recommendation | ❌ |
Get Multiple Recommendations | ❌ |
Get Default Recommendations | ❌ |
Get a Catalog Apple Curator | ❌ |
Get a Catalog Apple Curator's Relationship Directly by Name | ❌ |
Get Multiple Catalog Apple Curators | ❌ |
Get a Catalog Curator | ❌ |
Get a Catalog Curator's Relationship Directly by Name | ❌ |
Get Multiple Catalog Curators | ❌ |
Get a Catalog Genre | ❌ |
Get a Catalog Genre's Relationship Directly by Name | ❌ |
Get Multiple Catalog Genres | ❌ |
Get Catalog Top Charts Genres | ❌ |
Get Catalog Charts | ❌ |

