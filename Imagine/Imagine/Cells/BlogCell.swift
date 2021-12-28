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
    @IBOutlet weak var containerView: UIView!
    
    let cornerRadius: CGFloat = 8
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func prepareForReuse() {
        contentView.backgroundColor = .systemBackground
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let layer = contentView.layer
        layer.cornerRadius = cornerRadius
        containerView.layer.cornerRadius = cornerRadius
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.5
        
        let rect = CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        
    }
    
    var post:BlogPost? {
        didSet {
            if let post = post {
                headerLabel.text = post.title
                bodyLabel.text = post.subtitle
                createDateLabel.text = post.stringDate
                categoryLabel.text = post.category
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
