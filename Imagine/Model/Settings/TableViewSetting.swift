//
//  TableViewSetting.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class TableViewSetting {
    
    var headerText: String
    var type: TableViewSettingType
    var footerText: String?
    var cells = [TableViewSettingCell]()
    
    var addOnItems = [AddOnItem]()
    
    init(type: TableViewSettingType, headerText: String) {
        self.headerText = headerText
        self.type = type
    }
}
