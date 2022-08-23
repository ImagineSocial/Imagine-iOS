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
    func answerCommentTapped(comment: Comment)
}

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var profilePictureImageView: DesignableImage!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var inlineSeparatorView: UIView!
    @IBOutlet weak var niceButton: DesignableButton!
    @IBOutlet weak var answerButton: UIButton!
    @IBOutlet weak var inlineSeparatorLeadingConstraint: NSLayoutConstraint!
    
    var delegate: CommentCellDelegate?
    var handyHelper = HandyHelper.shared
    
    var comment: Comment? {
        didSet {
            if let comment = comment {
                if let user = comment.user {
                    nameLabel.text = user.name
                    if let urlString = user.imageURL, let url = URL(string: urlString) {
                        profilePictureImageView.sd_setImage(with: url, completed: nil)
                    }
                    if let currentUser = AuthenticationManager.shared.user {
                        if currentUser.uid == user.uid {
                            niceButton.setImage(nil, for: .normal)
                            niceButton.setTitle(String(comment.likes), for: .normal)
                        }
                    }
                } else {
                    nameLabel.text = Constants.strings.anonymPosterName
                    profilePictureImageView.image = UIImage(named: "anonym-user")
                }
                createDateLabel.text = comment.createTime.formatRelativeString()
                
                if comment.isIndented {
                    answerButton.isHidden = true
                    inlineSeparatorView.isHidden = false
                    inlineSeparatorLeadingConstraint.constant = 60
                }
                
                
                
                bodyLabel.text = comment.text
                layoutIfNeeded()
            }
        }
    }
    
    @IBAction func toUserTapped(_ sender: Any) {
        if let comment = comment, let user = comment.user {
            delegate?.userTapped(user: user)
        }
    }
    
    override func awakeFromNib() {
        let layer = niceButton.layer
        
        layer.borderColor = UIColor.label.cgColor
        layer.borderWidth = 0.5
    }
    
    override func prepareForReuse() {
        inlineSeparatorView.isHidden = true
        answerButton.isHidden = false
        inlineSeparatorLeadingConstraint.constant = 1
        niceButton.setImage(UIImage(named: "thanksButton"), for: .normal)
    }
    
    @IBAction func answerButtonTapped(_ sender: Any) {
        if let comment = comment {
            delegate?.answerCommentTapped(comment: comment)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if AuthenticationManager.shared.isLoggedIn, let comment = comment {
            handyHelper.setLikeOnComment(comment: comment, answerToComment: comment.parent)
            niceButton.setImage(nil, for: .normal)
            niceButton.setTitle(String(comment.likes+1), for: .normal)
        }
    }
}
