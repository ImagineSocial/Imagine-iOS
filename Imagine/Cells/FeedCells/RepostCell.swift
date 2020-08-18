//
//  RepostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class RePostCell : BaseFeedCell {
    
    
    @IBOutlet weak var translatedTitleLabel: UILabel!
    @IBOutlet weak var OGPostView: DesignablePopUp!
    @IBOutlet weak var originalCreateDateLabel: UILabel!
    @IBOutlet weak var originalTitleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
//    @IBOutlet weak var cellImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButton: DesignableButton!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ogPosterNameLabel: UILabel!
    @IBOutlet weak var reposterNameLabel: UILabel!
    @IBOutlet weak var repostDateLabel: UILabel!
    @IBOutlet weak var ogProfilePictureImageView: UIImageView!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        self.addSubview(buttonLabel)
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
        
        buttonLabel.textColor = .black
        
        // Profile Picture
        let layer = ogProfilePictureImageView.layer
        layer.cornerRadius = ogProfilePictureImageView.frame.width/2
        
        cellImageView.layer.cornerRadius = 5
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
        backgroundColor = .clear
//        contentView.backgroundColor = Constants.imagineColor
        cellImageView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImageView.sd_cancelCurrentImageLoad()
        cellImageView.image = nil
        
        ogProfilePictureImageView.sd_cancelCurrentImageLoad()
        ogProfilePictureImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        originalTitleLabel.text = nil
        translatedTitleLabel.text = nil
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    
    var post: Post? {
        didSet {
            setCell()
        }
    }
    
    func setCell(){
        if let post = post {
                        
            if ownProfile {
                thanksButton.setTitle(String(post.votes.thanks), for: .normal)
                wowButton.setTitle(String(post.votes.wow), for: .normal)
                haButton.setTitle(String(post.votes.ha), for: .normal)
                niceButton.setTitle(String(post.votes.nice), for: .normal)
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell()
                }
            } else {
                thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
                wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
                haButton.setImage(UIImage(named: "haButton"), for: .normal)
                niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
            }
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getName()
                }
            } else {
                setUser()
            }
            
            // Post Sachen einstellen
            translatedTitleLabel.text = post.title
            repostDateLabel.text = post.createTime
            
            commentCountLabel.text = String(post.commentCount)
            
            
            // Repost Sachen einstellen
            if let repost = post.repost {
                originalTitleLabel.text = repost.title
                originalCreateDateLabel.text = repost.createTime
                
                if repost.anonym {
                    if let anonymousName = post.anonymousName {
                        OPNameLabel.text = anonymousName
                    } else {
                        OPNameLabel.text = Constants.strings.anonymPosterName
                    }
                    ogProfilePictureImageView.image = UIImage(named: "anonym-user")
                } else {
                    ogPosterNameLabel.text = post.user.displayName
                    
                    // Profile Picture
                    if let url = URL(string: repost.user.imageURL) {
                        ogProfilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                    }
                }
                
                
                if let url = URL(string: repost.imageURL) {
                    cellImageView.isHidden = false      // Check ich nicht, aber geht!
                    cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
                
                // ReportView einstellen
                let reportViewOptions = handyHelper.setReportView(post: post)
                
                reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                reportViewButton.isHidden = reportViewOptions.buttonHidden
                reportViewLabel.text = reportViewOptions.labelText
                reportView.backgroundColor = reportViewOptions.backgroundColor
                
            } else {
                
                originalTitleLabel.text = "One Moment"
                originalCreateDateLabel.text = ""
                ogPosterNameLabel.text = ""
                
                // Profile Picture
               
                ogProfilePictureImageView.image = UIImage(named: "default-user")
                
                cellImageView.isHidden = false      // Check ich nicht, aber geht!
                cellImageView.image = UIImage(named: "default")
                
                reportViewHeightConstraint.constant = 0
                reportViewButton.isHidden = true
                reportViewLabel.text = ""
                reportView.backgroundColor = .white
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.setCell()
                }
            }
        }
    }
    
    func setUser() {
        if let post = post {
            if post.anonym {
                if let anonymousName = post.anonymousName {
                    OPNameLabel.text = anonymousName
                } else {
                    OPNameLabel.text = Constants.strings.anonymPosterName
                }
                profilePictureImageView.image = UIImage(named: "anonym-user")
            } else {
                reposterNameLabel.text = post.user.displayName
                // Profile Picture
                
                // Profile Picture
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                }
            }
        }
    }
    
    
    var index = 0
    func getName() {
        if index < 20 {
            if let post = self.post {
                if post.user.displayName == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getName()
                        self.index+=1
                    }
                } else {
                    setUser()
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
            showButtonText(post: post, button: thanksButton)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            showButtonText(post: post, button: wowButton)
        }
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            showButtonText(post: post, button: haButton)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            showButtonText(post: post, button: niceButton)
        }
    }
}


