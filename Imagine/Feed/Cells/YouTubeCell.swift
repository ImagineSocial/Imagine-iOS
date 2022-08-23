//
//  YouTubeCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import YoutubePlayer_in_WKWebView



class YouTubeCell: BaseFeedCell {
    
    static let identifier = "YouTubeCell"
    
    // MARK: - IBOutlets
    @IBOutlet weak var playerView: WKYTPlayerView!
        
    // MARK: - Cell Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
        
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        playerView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        playerView.stopVideo()
        
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
            
            if let linkURL = post.link?.url, let youtubeID = linkURL.youtubeID {
                // Not an actual solution because we cant cache the loading process, needs time everytime you see a youtubecell
                playerView.load(withVideoId: youtubeID, playerVars: ["playsinline":1])  // Plays in tableview, no auto fullscreen
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
            
            if let communityID = post.communityID {
                if post.community != nil {
                    setCommunity(for: post)
                } else {
                    getCommunity(with: communityID)
                }
            }
            
            titleLabel.text = post.title
            feedLikeView.setPost(post: post)
            

            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
}
