//
//  SettingCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class BaseCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    func setupViews() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SettingCell: BaseCell {
    
    let blockUserText = "Blockieren"
    let cameraText = "Kamera"
    let photoLibraryText = "Photo Library"
    let viewPicText = "Profilbild ansehen"
    let cancelText = "Abbrechen"
    let chatWithUser = "Chatten"
    
    let settingCellHeight: CGFloat = 60
    fileprivate var nameLabelLeadingConstraint: NSLayoutConstraint?
    
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.darkGray : UIColor.white
            
            nameLabel.textColor = isHighlighted ? UIColor.white : UIColor.black
            
            iconImageView.tintColor = isHighlighted ? UIColor.white : UIColor.darkGray
        }
    }
    
    var setting: Setting? {
        didSet {
            
            iconImageView.tintColor = UIColor.darkGray
            
            if let setting = setting {
                
                switch setting.settingType {
                case .cancel:
                    backgroundColor = UIColor(red:0.85, green:0.85, blue:0.85, alpha:1.0)
                    iconImageView.isHidden = true
                    nameLabel.textColor = .red
                    nameLabel.textAlignment = .center
                    nameLabelLeadingConstraint?.constant = 0
                    nameLabel.text = cancelText
                case .blockUser:
                    backgroundColor = .white
                    iconImageView.isHidden = false
                    nameLabel.textColor = .black
                    nameLabel.textAlignment = .left
                    nameLabelLeadingConstraint?.constant = settingCellHeight+10
                    iconImageView.image = UIImage(named: "collaboration")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = blockUserText
                case .camera:
                    backgroundColor = .white
                    iconImageView.isHidden = false
                    nameLabel.textColor = .black
                    nameLabel.textAlignment = .left
                    nameLabelLeadingConstraint?.constant = settingCellHeight+10
                    iconImageView.image = UIImage(named: "camera")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = cameraText
                case .photoLibrary:
                    backgroundColor = .white
                    iconImageView.isHidden = false
                    nameLabel.textColor = .black
                    nameLabel.textAlignment = .left
                    nameLabelLeadingConstraint?.constant = settingCellHeight+10
                    iconImageView.image = UIImage(named: "folder")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = photoLibraryText
                case .viewPicture:
                    backgroundColor = .white
                    iconImageView.isHidden = false
                    nameLabel.textColor = .black
                    nameLabel.textAlignment = .left
                    nameLabelLeadingConstraint?.constant = settingCellHeight+10
                    iconImageView.image = UIImage(named: "people")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = viewPicText
                case .chatWithUser:
                    backgroundColor = .white
                    iconImageView.isHidden = false
                    nameLabel.textColor = .black
                    nameLabel.textAlignment = .left
                    nameLabelLeadingConstraint?.constant = settingCellHeight+10
                    iconImageView.image = UIImage(named: "chat")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = chatWithUser
                default:
                    backgroundColor = .white
                }
            }
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Setting"
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "support")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override func setupViews() {
        super.setupViews()
        
        addSubview(nameLabel)
        addSubview(iconImageView)
        
        let imageHeight :CGFloat = settingCellHeight-settingCellHeight/2
        
        iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: imageHeight/2).isActive = true
        iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: imageHeight/2).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: imageHeight).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: imageHeight).isActive = true
        
        nameLabelLeadingConstraint = nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: settingCellHeight+10)
        nameLabelLeadingConstraint!.isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        nameLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: iconImageView.bottomAnchor).isActive = true
        
        
    }
}
