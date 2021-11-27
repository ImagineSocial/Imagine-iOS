//
//  ReportData.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class ReportData {
    var userCount: Int
    var earnings: Double
    var expenses: Double
    var donations: Double
    
    init(userCount: Int, earnings: Double, expenses: Double, donations: Double) {
        self.userCount = userCount
        self.earnings = earnings
        self.expenses = expenses
        self.donations = donations
    }
}
