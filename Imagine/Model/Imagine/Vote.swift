//
//  Vote.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class Vote {
    var title = ""
    var subtitle = ""
    var description = ""
    var stringDate = ""
    var endOfVoteDate = ""
    var cost = ""
    var costDescription = ""
    var impact = Impact.light
    var impactDescription = ""
    var timeToRealization = 0   // In month
    var realizationTimeDescription = ""
    var commentCount = 0
    var documentID = ""
    var createDate = Date()
}
