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
    
    var community: Community? {
        didSet {
            if let community = community {
                topicNameLabel.text = community.title
                
                if let imageURL = community.imageURL, let url = URL(string: imageURL) {
                    topicImageView.sd_setImage(with: url, completed: nil)
                } else {
                    topicImageView.image = UIImage(named: "default-community")
                }
            }
        }
    }
    
}
