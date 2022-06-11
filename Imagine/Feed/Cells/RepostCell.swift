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
        super.setCell()
        
        if let post = post {            
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
            
            if post.user == nil {
                if post.anonym {
                    self.setUser()
                } else {
                    self.checkForUser()
                }
            } else {
                setUser()
            }
            
            // Post Sachen einstellen
            translatedTitleLabel.text = post.title
            
            feedLikeView.setPost(post: post)
            
            
            // Repost Sachen einstellen
            if let repost = post.repost {
                originalTitleLabel.text = repost.title
                originalCreateDateLabel.text = repost.createdAt.formatForFeed()
                
                if repost.anonym {
                    ogProfilePictureImageView.image = UIImage(named: "anonym-user")
                } else {
                    
                    titleLabel.text = post.title
                    
                    if let repostUser = repost.user {
                        ogPosterNameLabel.text = repostUser.name
                        
                        
                        // Profile Picture
                        if let urlString = repostUser.imageURL, let url = URL(string: urlString) {
                            ogProfilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                        }
                    }
                }
                
                
                if let link = repost.image?.url, let url = URL(string: link) {
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
}


