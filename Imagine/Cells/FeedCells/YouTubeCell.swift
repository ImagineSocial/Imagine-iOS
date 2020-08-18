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
    
    @IBOutlet weak var playerView: WKYTPlayerView!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.addSubview(buttonLabel)
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
        
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
        backgroundColor = .clear
        playerView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        playerView.stopVideo()
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
        followTopicImageView.isHidden = true
        
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
    
    func setCell() {
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
            
            if let youtubeID = post.linkURL.youtubeID {
                // Not an actual solution because we cant cache the loading process, needs time everytime you see a youtubecell
                playerView.load(withVideoId: youtubeID, playerVars: ["playsinline":1])  // Plays in tableview, no auto fullscreen
            }
            
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
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
            
            if let fact = post.fact {
                self.factImageView.layer.borderColor = UIColor.lightText.cgColor
                                
                if fact.title == "" {
                    if fact.beingFollowed {
                        self.getFact(beingFollowed: true)
                    } else {
                        self.getFact(beingFollowed: false)
                    }
                } else {
                    self.loadFact()
                }
            }
            
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
                OPNameLabel.text = post.user.displayName
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
    
    func getFact(beingFollowed: Bool) {
        if let post = post {
            self.loadFact(post: post, beingFollowed: beingFollowed) {
                (fact) in
                post.fact = fact
                
                self.loadFact()
            }
        }
    }
    
    func loadFact() {
        if post!.isTopicPost {
            followTopicImageView.isHidden = false
        }
        
        if let url = URL(string: post!.fact!.imageURL) {
            self.factImageView.sd_setImage(with: url, completed: nil)
        } else {
            print("Set default Picture")
            if #available(iOS 13.0, *) {
                self.factImageView.backgroundColor = .systemBackground
            } else {
                self.factImageView.backgroundColor = .white
            }
            self.factImageView.image = UIImage(named: "FactStamp")
        }
    }
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            thanksButton.isEnabled = false
            delegate?.thanksTapped(post: post)
            post.votes.thanks = post.votes.thanks+1
            showButtonText(post: post, button: thanksButton)
        }
    }
    
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            wowButton.isEnabled = false
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            showButtonText(post: post, button: wowButton)
        }
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            haButton.isEnabled = false
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            showButtonText(post: post, button: haButton)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            niceButton.isEnabled = false
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            showButtonText(post: post, button: niceButton)
        }
    }
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let post = post {
            if !post.anonym {
                delegate?.userTapped(post: post)
            }
        }
    }
    
    @IBAction func linkedFactTapped(_ sender: Any) {
        if let post = post {
            if let fact = post.fact {
                delegate?.factTapped(fact: fact)
            }
        }
    }
}
