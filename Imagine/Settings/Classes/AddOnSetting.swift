//
//  Addo.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class AddOnSetting {
    var style: AddOnStyle
    var community: Community
    var addOnDocumentID: String
    var description: String
    var items: [AddOnItem]
    var imageURL: String?
    var title: String?
    var itemOrder: [String]?
    
    init(style: AddOnStyle, community: Community, addOnDocumentID: String, description: String, items: [AddOnItem]) {
        self.style = style
        self.community = community
        self.addOnDocumentID = addOnDocumentID
        self.description = description
        self.items = items
    }
}
