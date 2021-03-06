//
//  FinishedWorkItem.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class FinishedWorkItem {
    
    //MARK:- Variables
    var title: String
    var description: String
    var createDate: Date
    var createDateString: String
    
    var showDescription = false

    var campaignID: String?
    
    //MARK:- Initialization
    init(title: String, description: String, createDate: Date) {
        self.title = title
        self.description = description
        self.createDate = createDate
        self.createDateString = createDate.formatForFeed()
    }
}
