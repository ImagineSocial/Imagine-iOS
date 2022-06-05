//
//  Link.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

struct Link: Codable {
    var url: String
    var shortURL: String?
    var imageURL: String?
    var linkTitle: String?
    var description: String?
    var songwhip: Songwhip?
    var mediaHeight: Double?
    var mediaWidth: Double?
}

struct Songwhip: Codable {
    var musicType: String
    var releaseDate: Date
    var artist: SongwhipArtist
    var musicImage: String
}

struct SongwhipArtist: Codable {
    var name: String
    var image: String
}
