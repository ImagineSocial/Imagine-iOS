//
//  BlogCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 15.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class BlogCell : UICollectionViewCell {
    
    @IBOutlet weak var headerLabel:UILabel!
    @IBOutlet weak var bodyLabel:UILabel!
    @IBOutlet weak var createDateLabel:UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // add corner radius on `contentView`
        contentView.clipsToBounds = true
        backgroundColor = .clear
        
//        if #available(iOS 13.0, *) {
//            contentView.backgroundColor = .quaternarySystemFill
//        } else {
//            contentView.backgroundColor = .ios12secondarySystemBackground
//        }
    }
    
    override func prepareForReuse() {
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .systemBackground
        } else {
            contentView.backgroundColor = .white
        }
        contentView.layer.borderWidth = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margins = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        contentView.frame = contentView.frame.inset(by: margins)
        
//        categoryLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
//        headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
//        bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
//        createDateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        
    }
    
    var post:BlogPost? {
        didSet {
            if let post = post {
                headerLabel.text = post.title
                bodyLabel.text = post.subtitle
                createDateLabel.text = post.stringDate
                categoryLabel.text = "Thema: \(post.category)"
                nameLabel.text = post.poster
                
                if let url = URL(string: post.profileImageURL) {
                    profileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                } else {
                    profileImageView.image = UIImage(named: "ImagineSign")
                }
                
                profileImageView.layer.cornerRadius = profileImageView.frame.width/2
                profileImageView.clipsToBounds = true
            }
        }
    }
    
}
