//
//  FollowedTopicCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class FollowedTopicCell: UICollectionViewCell {
    
    @IBOutlet weak var topicImageView: DesignableImage!
    @IBOutlet weak var topicNameLabel: UILabel!
    
    var fact: Community? {
        didSet {
            if let fact = fact {
                topicNameLabel.text = fact.title
                
                if let url = URL(string: fact.imageURL) {
                    topicImageView.sd_setImage(with: url, completed: nil)
                } else {
                    topicImageView.image = UIImage(named: "default-community")
                }
            }
        }
    }
    
}
