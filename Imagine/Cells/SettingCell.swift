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
    
    let blockUserText = NSLocalizedString("settingCell_block_label", comment: "block person")
    let cameraText = NSLocalizedString("settingCell_camera_label", comment: "camera")
    let photoLibraryText = NSLocalizedString("settingCell_change_picture", comment: "change picture")
    let viewPicText = NSLocalizedString("settingCell_see_picture", comment: "see picture")
    let cancelText = NSLocalizedString("cancel", comment: "cancel")
    let chatWithUserText = NSLocalizedString("settingCell_write_message_label", comment: "write message")
    let deleteFriendText = NSLocalizedString("settingCell_delete_as_friend_label", comment: "delete as friend")
    
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
                    iconImageView.image = UIImage(named: "block")
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
                    iconImageView.image = UIImage(named: "messageBubble")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = chatWithUserText
                case .deleteFriend:
                    backgroundColor = .white
                    iconImageView.isHidden = false
                    nameLabel.textColor = .black
                    nameLabel.textAlignment = .left
                    nameLabelLeadingConstraint?.constant = settingCellHeight+10
                    iconImageView.image = UIImage(named: "people")?.withRenderingMode(.alwaysTemplate)
                    nameLabel.text = deleteFriendText
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
