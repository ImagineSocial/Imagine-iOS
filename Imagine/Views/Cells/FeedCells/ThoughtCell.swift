//
//  ThoughtCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ThoughtCell : BaseFeedCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var titleToLikeButtonsConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
        
        titleLabel.sizeToFit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                        
        resetValues()
    }
    
    //MARK:- Set Cell
    override func setCell() {
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
            
            if post.description != "" {
                self.titleToLikeButtonsConstraint.constant = 25
                let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
                let descriptionText = post.description.replacingOccurrences(of: "\\n", with: newLineString)
                self.descriptionLabel.text = descriptionText
            } else {
                self.descriptionLabel.text = ""
                self.titleToLikeButtonsConstraint.constant = 10
            }
            
            titleLabel.text = post.title
            descriptionPreviewLabel.text = post.description
            commentCountLabel.text = String(post.commentCount)
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getUser()
                }
            } else {
                setUser()
            }
            
            if let fact = post.fact {
                                
                if fact.title == "" {
                    if fact.beingFollowed {
                        self.getCommunity(beingFollowed: true)
                    } else {
                        self.getCommunity(beingFollowed: false)
                    }
                } else {
                    self.setCommunity(post: post)
                }
            }
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
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
