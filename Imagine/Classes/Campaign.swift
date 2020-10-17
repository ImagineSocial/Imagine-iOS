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
    var createTime: Date = Date()
    var supporter = 0
    var opposition = 0
    var category: CampaignCategory?
}

class CampaignCategory {
    var title:String
    var type: CampaignType = .proposal
    
    init(title: String, type: CampaignType) {
        self.title = title
        self.type = type
    }
    
}
