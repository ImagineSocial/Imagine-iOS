//
//  Campaign.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class Campaign {
    var title = ""
    var cellText = ""
    var descriptionText = ""
    var documentID = ""
    var createDate = ""
    var supporter = 0
    var opposition = 0
    var category = ""
}

class CampaignCategory {
    var title:String
    var type: CampaignType = .general
    
    init(title: String, type: CampaignType) {
        self.title = title
        self.type = type
    }
    
}
