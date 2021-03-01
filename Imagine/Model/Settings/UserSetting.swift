//
//  UserSetting.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class UserSetting {
    var name: String
    var statusText: String?
    var OP: String
    var imageURL: String?
    var birthday: Date?
    var location: Location?
    var locationIsPublic = false
    
    var youTubeLink: String?
    var youTubeDescription: String?
    var patreonLink: String?
    var patreonDescription: String?
    var instagramLink: String?
    var instagramDescription: String?
    var twitterLink: String?
    var twitterDescription: String?
    var songwhipLink: String?
    var songwhipDescription: String?
    
    init(name: String, OP: String) {
        self.name = name
        self.OP = OP
    }
}
