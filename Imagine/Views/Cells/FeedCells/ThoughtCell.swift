//
//  ThoughtCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ThoughtCell : BaseFeedCell {
    
    @IBOutlet weak var titleToLikeButtonsConstraint: NSLayoutConstraint!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.addSubview(buttonLabel)
        buttonLabel.textColor = .black
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
        
        titleLabel.sizeToFit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        descriptionPreviewLabel.text = ""
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        titleLabel.text = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
        followTopicImageView.isHidden = true
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    
    var post:Post? {
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
            createDateLabel.text = post.createTime
            
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
            
            
            // Profile Picture
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
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
                } else {
                    profilePictureImageView.image = UIImage(named: "default-user")
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
            if let fact = post.fact {
                self.loadFact(language: post.language, fact: fact, beingFollowed: beingFollowed) {
                    (fact) in
                    post.fact = fact
                    
                    self.loadFact()
                }
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
    
    @IBAction func reportTapped(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
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
        if let fact = post?.fact {
            delegate?.factTapped(fact: fact)
        }
    }
    
    
}
