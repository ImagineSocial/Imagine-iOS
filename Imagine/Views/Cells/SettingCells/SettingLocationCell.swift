//
//  SettingLocationCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class SettingLocationCell: UITableViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var setLocationTitleLabel: UILabel!
    @IBOutlet weak var choosenLocationLabel: UILabel!
    
    //MARK:- Variables
    var delegate: SettingCellDelegate?
    var indexPath: IndexPath?
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                setLocationTitleLabel.text = setting.titleText
                if let value = setting.value as? Location {
                    choosenLocationLabel.text = value.title
                } else {
                    choosenLocationLabel.text = NSLocalizedString("setting_location_cell_text", comment: "choose a location")
                }
            }
        }
    }
    
    //MARK:- Actions
    @IBAction func setLocationButtonTapped(_ sender: Any) {
        if let setting = config, let indexPath = indexPath {
            if let location = setting.value as? Location{
                delegate?.selectLocation(location: location, type: setting.settingChange, forIndexPath: indexPath)
            } else {
                delegate?.selectLocation(location: nil, type: setting.settingChange, forIndexPath: indexPath)
            }
        }
    }
}
