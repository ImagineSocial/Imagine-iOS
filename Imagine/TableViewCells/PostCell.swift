//
//  PostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit


class PostCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportButton: DesignableButton!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    @IBOutlet weak var cellCreateDateLabel: UILabel!
    
    
    var postObject: Post!
    var delegate: PostCellDelegate?
    
    func setPost(post: Post) {
        postObject = post
    }
    
    
    
    @IBAction func reportPressed(_ sender: Any) {
        delegate?.reportTapped(post: postObject)
    }
    
}
