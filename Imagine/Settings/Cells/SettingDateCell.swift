//
//  SettingDateCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class SettingDateCell: UITableViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var settingTitleLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    //MARK:- Variables
    var delegate: SettingCellDelegate?
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                settingTitleLabel.text = setting.titleText
                if let value = setting.value as? Date {
                    datePicker.setDate(value, animated: true)
                }
            }
        }
    }
    
    //MARK:- Actions
    func newTextReady(text: String) {
        if let setting = config {
            delegate?.gotChanged(type: setting.settingChange, value: text)
        }
    }
 
    
    @IBAction func datePickerChanged(_ sender: Any) {
        if let setting = config {
            delegate?.gotChanged(type: setting.settingChange, value: datePicker.date)
        }
    }
}
