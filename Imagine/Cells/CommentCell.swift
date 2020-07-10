//
//  CommentCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol CommentCellDelegate {
    func userTapped(user: User)
}

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var profilePictureImageView: DesignableImage!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    
    var delegate: CommentCellDelegate?
    
    var comment: Comment? {
        didSet {
            if let comment = comment {
                if let user = comment.user {
                    nameLabel.text = user.displayName
                    if let url = URL(string: user.imageURL) {
                        profilePictureImageView.sd_setImage(with: url, completed: nil)
                    }
                } else {
                    nameLabel.text = Constants.strings.anonymPosterName
                    profilePictureImageView.image = UIImage(named: "anonym-user")
                }
                createDateLabel.text = comment.createTime.formatRelativeString()
                bodyLabel.text = comment.text
            }
        }
    }
    
    @IBAction func toUserTapped(_ sender: Any) {
        if let comment = comment, let user = comment.user {
            delegate?.userTapped(user: user)
        }
    }
}
