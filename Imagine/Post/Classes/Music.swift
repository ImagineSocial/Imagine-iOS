//
//  Music.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

enum MusicType: String, Codable {
    case track
    case album
}

class Music: Codable {
    var type: MusicType
    var name: String
    var artist: String
    var releaseDate: Date?
    var artistImageURL: String?
    var musicImageURL: String
    var songwhipURL: String
    
    ///Playlist init
    init(type:MusicType, name: String, artist: String, musicImageURL: String, songwhipURL: String) {
        self.type = type
        self.name = name
        self.artist = artist
        self.musicImageURL = musicImageURL
        self.songwhipURL = songwhipURL
    }
    
    init(type: MusicType, name: String, artist: String, releaseDate: Date, artistImageURL: String, musicImageURL: String, songwhipURL: String) {
        self.type = type
        self.name = name
        self.artist = artist
        self.releaseDate = releaseDate
        self.artistImageURL = artistImageURL
        self.musicImageURL = musicImageURL
        self.songwhipURL = songwhipURL
    }
    
    func getSongwhip() -> Songwhip {
        Songwhip(title: name, musicType: type.rawValue, releaseDate: releaseDate ?? Date(), artist: SongwhipArtist(name: name, image: artistImageURL ?? ""), musicImage: musicImageURL)
    }
}
