//
//  CommentCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

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
    
    var delegate: CommentCellDelegate?
    var handyHelper = HandyHelper()
    let auth = Auth.auth()
    
    var comment: Comment? {
        didSet {
            if let comment = comment {
                if let user = comment.user {
                    nameLabel.text = user.displayName
                    if let url = URL(string: user.imageURL) {
                        profilePictureImageView.sd_setImage(with: url, completed: nil)
                    }
                    if let currentUser = auth.currentUser {
                        if currentUser.uid == user.userUID {
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
                } else {
                    bodyLabel.text = comment.text
                }
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
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
        layer.borderWidth = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let comment = comment {
            if comment.isIndented {
                let margins = UIEdgeInsets(top: 0, left: 65, bottom: 0, right: 0)
                contentView.frame = contentView.frame.inset(by: margins)
                
                bodyLabel.text = comment.text
                inlineSeparatorView.isHidden = false
            }
        }
    }
    
    override func prepareForReuse() {
        inlineSeparatorView.isHidden = true
        answerButton.isHidden = false
    }
    
    @IBAction func answerButtonTapped(_ sender: Any) {
        if let comment = comment {
            delegate?.answerCommentTapped(comment: comment)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let _ = auth.currentUser, let comment = comment {
            handyHelper.setLikeOnComment(comment: comment, answerToComment: comment.parent)
            niceButton.setImage(nil, for: .normal)
            niceButton.setTitle(String(comment.likes+1), for: .normal)
        }
    }
}
