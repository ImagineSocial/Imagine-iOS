//
//  SettingSwitchCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class SettingSwitchCell: UITableViewCell {
    
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var settingSwitch: UISwitch!
    
    var delegate: SettingCellDelegate?
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                settingTitleLabel.text = setting.titleText
                
                if let value = setting.value as? Bool {
                    settingSwitch.isOn = value
                }
            }
        }
    }
    
    @IBAction func settingSwitchChanged(_ sender: Any) {
        if let setting = config {
            let switchState = settingSwitch.isOn
            delegate?.gotChanged(type: setting.settingChange, value: switchState)
        }
    }
}
