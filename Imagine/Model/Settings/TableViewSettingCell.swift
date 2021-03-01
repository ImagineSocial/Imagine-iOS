//
//  TableViewSettingCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation

class TableViewSettingCell {
    var type: SettingCellType
    var settingChange: SettingChangeType
    var titleText: String?
    var characterLimit: Int?
    var value: Any
    
    init(value: Any, type:SettingCellType, settingChange: SettingChangeType) {
        self.value = value
        self.type = type
        self.settingChange = settingChange
    }
}
