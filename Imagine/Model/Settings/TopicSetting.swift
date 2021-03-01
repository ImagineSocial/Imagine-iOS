//
//  TopicSetting.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class TopicSetting {
    var title: String
    var description: String
    var OP: String
    var isAddOnFirstView = false
    var imageURL: String?
    
    init(title: String, description: String, OP: String) {
        self.title = title
        self.description = description
        self.OP = OP
    }
}
