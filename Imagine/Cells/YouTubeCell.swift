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
    
    var imgurID: String? {
        // Better pattern possible, couldnt find solution for an "logical or" for "gallery/" und ".com/"
        
        if self.contains("imgur") {
            if self.contains("gallery") {
                print("Eine Galerie")
                
                let pattern = "(?<=gallery/)([\\w-]++)" //|(?<=.com/)
                
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: count)
                
                guard let result = regex?.firstMatch(in: self, range: range) else {
                    return nil
                }
                //https://i.imgur.com/CmxSTlU.mp4
                print("Klappt: \((self as NSString).substring(with: result.range))")
                return (self as NSString).substring(with: result.range)
            } else {
                print("Keine Galerie")
                
                let pattern = "(?<=.com/)([\\w-]++)" //|(?<=.com/)
                
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(location: 0, length: count)
                
                guard let result = regex?.firstMatch(in: self, range: range) else {
                    return nil
                }
                //https://i.imgur.com/CmxSTlU.mp4
                print("Klappt: \((self as NSString).substring(with: result.range))")
                return (self as NSString).substring(with: result.range)
            }
        } else {
            print("Not an Imgur link")
            return nil
        }
    }
}

class YouTubeCell: BaseFeedCell {
    
    @IBOutlet weak var playerView: WKYTPlayerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.addSubview(buttonLabel)
        
        if #available(iOS 13.0, *) {
            thanksButton.layer.borderColor = UIColor.label.cgColor
            wowButton.layer.borderColor = UIColor.label.cgColor
            haButton.layer.borderColor = UIColor.label.cgColor
            niceButton.layer.borderColor = UIColor.label.cgColor
        } else {
            thanksButton.layer.borderColor = UIColor.black.cgColor
            wowButton.layer.borderColor = UIColor.black.cgColor
            haButton.layer.borderColor = UIColor.black.cgColor
            niceButton.layer.borderColor = UIColor.black.cgColor
        }
        thanksButton.layer.borderWidth = 0.5
        wowButton.layer.borderWidth = 0.5
        haButton.layer.borderWidth = 0.5
        niceButton.layer.borderWidth = 0.5
        
        thanksButton.setImage(nil, for: .normal)
        wowButton.setImage(nil, for: .normal)
        haButton.setImage(nil, for: .normal)
        niceButton.setImage(nil, for: .normal)
        
        thanksButton.imageView?.contentMode = .scaleAspectFit
        wowButton.imageView?.contentMode = .scaleAspectFit
        haButton.imageView?.contentMode = .scaleAspectFit
        niceButton.imageView?.contentMode = .scaleAspectFit
        
        factImageView.layer.cornerRadius = 3
        factImageView.layer.borderWidth = 1
        factImageView.layer.borderColor = UIColor.clear.cgColor
        
        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
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
                    self.getFact()
                } else {
                    if let url = URL(string: fact.imageURL) {
                        self.factImageView.sd_setImage(with: url, completed: nil)
                    } else {
                        self.factImageView.image = UIImage(named: "FactStamp")
                        if #available(iOS 13.0, *) {
                            self.factImageView.backgroundColor = .systemBackground
                        } else {
                            self.factImageView.backgroundColor = .white
                        }
                    }
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
    
    func getFact() {
        if let post = post {
            self.loadFact(post: post) {
                (fact) in
                post.fact = fact
                
                if let url = URL(string: post.fact!.imageURL) {
                    self.factImageView.sd_setImage(with: url, completed: nil)
                } else {
                    self.factImageView.image = UIImage(named: "FactStamp")
                    if #available(iOS 13.0, *) {
                        self.factImageView.backgroundColor = .systemBackground
                    } else {
                        self.factImageView.backgroundColor = .white
                    }
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