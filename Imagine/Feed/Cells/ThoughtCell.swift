//
//  ThoughtCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ThoughtCell: BaseFeedCell {
    
    static let identifier = "ThoughtCell"
    
    // MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
        
        titleLabel.sizeToFit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                        
        resetValues()
    }
    
    // MARK: - Set Cell
    override func setCell() {
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
            
            titleLabel.text = post.title
            feedLikeView.setPost(post: post)
            
            if post.user == nil {
                if post.anonym {
                    self.setUser()
                } else {
                    self.checkForUser()
                }
            } else {
                setUser()
            }
            
            if let communityID = post.communityID {
                if post.community != nil {
                    setCommunity(for: post)
                } else {
                    getCommunity(with: communityID)
                }
            }
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
}
