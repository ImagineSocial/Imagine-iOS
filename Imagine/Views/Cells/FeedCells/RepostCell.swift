//
//  RepostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class RePostCell : BaseFeedCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var translatedTitleLabel: UILabel!
    @IBOutlet weak var OGPostView: DesignablePopUp!
    @IBOutlet weak var originalCreateDateLabel: UILabel!
    @IBOutlet weak var originalTitleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var ogPosterNameLabel: UILabel!
    @IBOutlet weak var ogProfilePictureImageView: UIImageView!
    
        
    //MARK:- View Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
                
        // Profile Picture
        ogProfilePictureImageView.layer.cornerRadius = ogProfilePictureImageView.frame.width/2
        
        cellImageView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImageView.sd_cancelCurrentImageLoad()
        cellImageView.image = nil
        
        ogProfilePictureImageView.sd_cancelCurrentImageLoad()
        ogProfilePictureImageView.image = nil
        
        originalTitleLabel.text = nil
        translatedTitleLabel.text = nil
        
        resetValues()
    }
    
    //MARK:- Set Cell
    override func setCell(){
        if let post = post {
            feedUserView.delegate = self
            
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell(post: post)
                }
            } else {
                setDefaultButtonImages()
            }
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getUser()
                }
            } else {
                setUser()
            }
            
            // Post Sachen einstellen
            translatedTitleLabel.text = post.title
            
            commentCountLabel.text = String(post.commentCount)
            
            
            // Repost Sachen einstellen
            if let repost = post.repost {
                originalTitleLabel.text = repost.title
                originalCreateDateLabel.text = repost.createTime
                
                if repost.anonym {
                    ogProfilePictureImageView.image = UIImage(named: "anonym-user")
                } else {
                    ogPosterNameLabel.text = repost.user.displayName
                    titleLabel.text = post.title

                    // Profile Picture
                    if let url = URL(string: repost.user.imageURL) {
                        ogProfilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                    }
                }
                
                
                if let url = URL(string: repost.imageURL) {
                    cellImageView.isHidden = false      // Check ich nicht, aber geht!
                    cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
                
                setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
                
            } else {
                
                originalTitleLabel.text = "One Moment"
                originalCreateDateLabel.text = ""
                ogPosterNameLabel.text = ""
                
                // Profile Picture
               
                ogProfilePictureImageView.image = UIImage(named: "default-user")
                
                cellImageView.isHidden = false      // Check ich nicht, aber geht!
                cellImageView.image = UIImage(named: "default")
                
                reportViewHeightConstraint.constant = 0
                reportViewButtonInTop.isHidden = true
                reportViewLabel.text = ""
                reportView.backgroundColor = .white
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.setCell()
                }
            }
        }
    }
    
    //MARK:- IBActions

    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: thanksButton)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: wowButton)
        }
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: haButton)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: niceButton)
        }
    }
}


