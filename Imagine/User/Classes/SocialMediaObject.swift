//
//  SocialMediaObject.swift
//  Imagine
//
//  Created by Don Malte on 03.08.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation

enum SocialMediaType {
    case patreon
    case youTube
    case instagram
    case twitter
    case songwhip
}

class SocialMediaObject {
    var type: SocialMediaType
    var link: String
    var description: String?
    
    init(type: SocialMediaType, link: String, description: String?) {
        self.type = type
        self.link = link
        self.description = description
    }
}
