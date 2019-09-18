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

class YouTubeCell: BaseFeedCell {
    
    @IBOutlet weak var playerView: WKYTPlayerView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        self.addSubview(buttonLabel)
        
        thanksButton.layer.borderWidth = 1.5
        thanksButton.layer.borderColor = thanksColor.cgColor
        wowButton.layer.borderWidth = 1.5
        wowButton.layer.borderColor = wowColor.cgColor
        haButton.layer.borderWidth = 1.5
        haButton.layer.borderColor = haColor.cgColor
        niceButton.layer.borderWidth = 1.5
        niceButton.layer.borderColor = niceColor.cgColor
        
        thanksButton.setImage(nil, for: .normal)
        wowButton.setImage(nil, for: .normal)
        haButton.setImage(nil, for: .normal)
        niceButton.setImage(nil, for: .normal)
        
        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        // add corner radius on `contentView`
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        backgroundColor =  Constants.backgroundColorForTableViews
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        playerView.stopVideo()
    }
    
    
    
    var post: Post? {
        didSet {
            
            setCell()
        }
    }
    
    func setCell() {
        if let post = post {
            
            print("Set 'YouTube' Post")
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
                thanksButton.setImage(UIImage(named: "thanks"), for: .normal)
                wowButton.setImage(UIImage(named: "wow"), for: .normal)
                haButton.setImage(UIImage(named: "ha"), for: .normal)
                niceButton.setImage(UIImage(named: "nice"), for: .normal)
            }
            
            if let youtubeID = post.linkURL.youtubeID {
                // Not an actual solution because we cant cache the loading process, needs time everytime you see a youtubecell
                playerView.load(withVideoId: youtubeID, playerVars: ["playsinline":1])  // Plays in tableview, no auto fullscreen
            }
            
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
            if post.user.name == "" {
                self.getName()
            }
            
            nameLabel.text = "\(post.user.name) \(post.user.surname)"
            createDateLabel.text = post.createTime
            
            titleLabel.text = post.title
            
            commentCountLabel.text = String(post.commentCount)
            
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
    
    var index = 0
    func getName() {
        if index < 20 {
            if let post = self.post {
                if post.user.name == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getName()
                        self.index+=1
                    }
                } else {
                    setCell()
                }
            }
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: Any) {
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
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.userTapped(post: post)
        }
    }
}
