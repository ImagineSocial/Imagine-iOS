//
//  ThoughtCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ThoughtCell : BaseFeedCell {
    
    @IBOutlet weak var profilePictureImageView : UIImageView!
    @IBOutlet weak var ogPosterLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        self.addSubview(buttonLabel)
        buttonLabel.textColor = .black
        
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
        
        titleLabel.sizeToFit()
        
        //Profile Picture
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
        backgroundColor =  Constants.backgroundColorForTableViews
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        titleLabel.text = nil
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
                thanksButton.setImage(UIImage(named: "thanks"), for: .normal)
                wowButton.setImage(UIImage(named: "wow"), for: .normal)
                haButton.setImage(UIImage(named: "ha"), for: .normal)
                niceButton.setImage(UIImage(named: "nice"), for: .normal)
            }
            
            titleLabel.text = post.title
            
            commentCountLabel.text = String(post.commentCount)
            
            
            if post.user.name == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getName()
                }
            } else {
                setUser()
            }
            
            createDateLabel.text = post.createTime
            ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
            
            // Profile Picture
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
            // ReportView einstellen
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
                ogPosterLabel.text = Constants.strings.anonymPosterName
                profilePictureImageView.image = UIImage(named: "default-user")
            } else {
                ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
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
                if post.user.name == "" {
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
    
    
}
