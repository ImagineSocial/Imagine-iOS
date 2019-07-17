//
//  RepostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol RepostCellDelegate {
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
}

class RePostCell : UITableViewCell {
    
    
    @IBOutlet weak var translatedTitleLabel: UILabel!
    @IBOutlet weak var OGPostView: DesignablePopUp!
    @IBOutlet weak var originalCreateDateLabel: UILabel!
    @IBOutlet weak var originalTitleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButton: DesignableButton!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var ogPosterNameLabel: UILabel!
    @IBOutlet weak var reposterNameLabel: UILabel!
    @IBOutlet weak var repostDateLabel: UILabel!
    @IBOutlet weak var reposterProfilePictureImageView: UIImageView!
    @IBOutlet weak var thanksCountLabel: UILabel!
    @IBOutlet weak var wowCountLabel: UILabel!
    @IBOutlet weak var haCountLabel: UILabel!
    @IBOutlet weak var niceCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    var delegate: RepostCellDelegate?
    let handyHelper = HandyHelper()
    
    var post: Post? {
        didSet {
            if let post = post {
                cellImageView.image = nil
                profilePictureImageView.image = UIImage(named: "default-user")
                originalTitleLabel.text = nil
                translatedTitleLabel.text = nil
                
                OGPostView.layer.borderWidth = 1
                OGPostView.layer.borderColor = UIColor.black.cgColor
                
                // Post Sachen einstellen
                translatedTitleLabel.text = post.title
                reposterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                repostDateLabel.text = post.createTime
                
                thanksCountLabel.text = "thanks"
                wowCountLabel.text = "wow"
                haCountLabel.text = "ha"
                niceCountLabel.text = "nice"
                commentCountLabel.text = String(post.commentCount)
                
                // Profile Picture
                let layer = reposterProfilePictureImageView.layer
                layer.cornerRadius = reposterProfilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.user.imageURL) {
                    reposterProfilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                
                // Repost Sachen einstellen
                if let repost = post.repost {
                    originalTitleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    originalTitleLabel.text = repost.title
                    originalCreateDateLabel.text = repost.createTime
                    ogPosterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                    
                    // Profile Picture
                    let layer = profilePictureImageView.layer
                    layer.cornerRadius = profilePictureImageView.frame.width/2
                    layer.borderWidth = 0.1
                    layer.borderColor = UIColor.black.cgColor
                    
                    if let url = URL(string: repost.user.imageURL) {
                        profilePictureImageView.sd_setImage(with: url, completed: nil)
                    }
                    
                    if let url = URL(string: repost.imageURL) {
                        if let repostCellImageView = cellImageView {
                            
                            repostCellImageView.isHidden = false      // Check ich nicht, aber geht!
                            repostCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                            repostCellImageView.layer.cornerRadius = 5
                        }
                    }
                    
                    // ReportView einstellen
                    let reportViewOptions = handyHelper.setReportView(post: post)
                    
                    reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                    reportViewButton.isHidden = reportViewOptions.buttonHidden
                    reportViewLabel.text = reportViewOptions.labelText
                    reportView.backgroundColor = reportViewOptions.backgroundColor
                    
                } else {
                    translatedTitleLabel.text = "Hier ist was schiefgelaufen!"
                    print("Hier ist was schiefgelaufen: \(post.title)")
                }
            }
        }
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.thanksTapped(post: post)
            post.votes.thanks = post.votes.thanks+1
            thanksCountLabel.text = String(post.votes.thanks)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            wowCountLabel.text = String(post.votes.wow)
        }
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            haCountLabel.text = String(post.votes.ha)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            niceCountLabel.text = String(post.votes.nice)
        }
    }
    
    
    
}


