//
//  Link.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class Link: Codable {
    var imageURL: String?
    var link: String
    var shortURL: String
    var linkTitle: String
    var description: String
    var songwhip: Songwhip?

    
    init(link: String, title: String, description: String, shortURL: String, imageURL: String?) {
        self.link = link
        self.linkTitle = title
        self.description = description
        self.shortURL = shortURL
        self.imageURL = imageURL
    }
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
