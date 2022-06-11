//
//  SearchUserCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.10.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class SearchUserCell: UICollectionViewCell {
    var user:User? {
        didSet {
            if let user = user {
                profilePictureImageView.image = nil
                nameLabel.text = user.name
                if let urlString = user.imageURL, let url = URL(string: urlString) {
                    profilePictureImageView.sd_setImage(with: url, completed: nil)
                } else {
                    profilePictureImageView.image = UIImage(named: "default-user")
                }
            }
        }
    }
    
    private let nameLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .label
        lbl.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let profilePictureImageView : UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "default-user"))
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 5
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(nameLabel)
        addSubview(profilePictureImageView)
        
        profilePictureImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        profilePictureImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        nameLabel.leadingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
    }
    
    override func prepareForReuse() {
        profilePictureImageView.image = UIImage(named: "default-user")
        nameLabel.text = ""
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

