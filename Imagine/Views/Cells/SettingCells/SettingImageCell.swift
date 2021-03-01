//
//  SettingImageCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class SettingImageCell: UITableViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var settingImageView: DesignableImage!
    
    //MARK:- Variables
    var delegate: SettingCellDelegate?
    var indexPath: IndexPath?
    
    var newImage: UIImage? {
        didSet {
            settingImageView.image = newImage!
        }
    }
    
    var settingFor: DestinationForSettings? {
        didSet {
            if let settingFor = settingFor  {
                switch settingFor {
                case .community:
                    settingImageView.image = UIImage(named: "default")
                case .userProfile:
                    settingImageView.image = UIImage(named: "default-user")
                case .addOn:
                    settingImageView.image = UIImage(named: "default")
                }
            }
        }
    }
    
    var config: TableViewSettingCell? {
        didSet {
            if let setting = config {
                if let imageURL = setting.value as? String {
                    if let url = URL(string: imageURL) {
                        settingImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        settingImageView.image = UIImage(named: "default")
                    }
                }
            }
        }
    }
    
    //MARK:- Actions
    @IBAction func changePictureTapped(_ sender: Any) {
        if let indexPath = indexPath, let setting = config {
            delegate?.selectPicture(type: setting.settingChange, forIndexPath: indexPath)
        }
    }
    
    func pictureSelected(imageURL: String) {
        if let setting = config {
            delegate?.gotChanged(type: setting.settingChange, value: imageURL)
        }
    }
    
}
