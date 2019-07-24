//
//  YouTubeCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import YoutubePlayer_in_WKWebView

extension String {
    var youtubeID: String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: count)
        
        guard let result = regex?.firstMatch(in: self, range: range) else {
            return nil
        }
        
        return (self as NSString).substring(with: result.range)
    }
}

class YouTubeCell: UITableViewCell {
    
    let handyHelper = HandyHelper()
    
    @IBOutlet weak var playerView: WKYTPlayerView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var niceCountLabel: UILabel!
    @IBOutlet weak var haCountLabel: UILabel!
    @IBOutlet weak var wowCountLabel: UILabel!
    @IBOutlet weak var thanksCountLabel: UILabel!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    var post: Post? {
        didSet {
            profilePictureImageView.image = UIImage(named: "default-user")
            titleLabel.text = nil
            
            if let post = post {
                if let youtubeID = post.linkURL.youtubeID {
                    playerView.load(withVideoId: youtubeID)
                }
                
                // Profile Picture
                let layer = profilePictureImageView.layer
                layer.cornerRadius = profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                nameLabel.text = "\(post.user.name) \(post.user.surname)"
                createDateLabel.text = post.createTime
                
                titleLabel.text = post.title
                titleLabel.adjustsFontSizeToFitWidth = true
                
                commentCountLabel.text = String(post.commentCount)
                thanksCountLabel.text = "thanks"
                wowCountLabel.text = "wow"
                haCountLabel.text = "ha"
                niceCountLabel.text = "nice"
                
                // LabelHeight calculated by the number of letters
                let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                titleLabelHeightConstraint.constant = labelHeight
                
                // Set ReportView
                let reportViewOptions = handyHelper.setReportView(post: post)
                
                reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                reportViewButtonInTop.isHidden = reportViewOptions.buttonHidden
                reportViewLabel.text = reportViewOptions.labelText
                reportView.backgroundColor = reportViewOptions.backgroundColor
            }
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: Any) {
    }
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
    }
    @IBAction func haButtonTapped(_ sender: Any) {
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
    }
    
}
