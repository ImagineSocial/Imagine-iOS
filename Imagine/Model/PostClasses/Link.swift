//
//  Link.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class Link {
    var imageURL: String?
    var link: String
    var shortURL: String
    var linkTitle: String
    var linkDescription: String
    
    init(link: String, title: String, description: String, shortURL: String, imageURL: String?) {
        self.link = link
        self.linkTitle = title
        self.linkDescription = description
        self.shortURL = shortURL
        self.imageURL = imageURL
    }
}
