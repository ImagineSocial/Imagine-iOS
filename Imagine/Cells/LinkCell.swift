//
//  LinkCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SwiftLinkPreview

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

class LinkCell : BaseFeedCell {
    
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var ogPosterNameLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var linkThumbNailImageView: UIImageView!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
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
        
        linkThumbNailImageView.layer.cornerRadius = 3
        

        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        titleLabel.layoutIfNeeded()
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
        backgroundColor =  Constants.backgroundColorForTableViews
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        urlLabel.text = nil
        linkThumbNailImageView.sd_cancelCurrentImageLoad()
        linkThumbNailImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
    }
    
    var post :Post? {
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
            
            commentCountLabel.text = String(post.commentCount)
            
            // Profile Picture
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
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
            ogPosterNameLabel.text = "\(post.user.name) \(post.user.surname)"
            
            titleLabel.text = post.title
            
            // Preview des Links anzeigen
            slp.preview(post.linkURL, onSuccess: { (result) in
                
                // Hat sogar ne Cache, wäre cool für die Dauer der Ladezeiten:
                //https://github.com/LeonardoCardoso/SwiftLinkPreview
                
                if let imageURL = result.image {
                    self.linkThumbNailImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
                if let linkSource = result.canonicalUrl {
                    self.urlLabel.text = linkSource
                }
            }) { (error) in
                print("We have an error: \(error.localizedDescription)")
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
                ogPosterNameLabel.text = Constants.strings.anonymPosterName
                profilePictureImageView.image = UIImage(named: "default-user")
            } else {
                ogPosterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                
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
    
    @IBAction func linkTapped(_ sender: Any) {
        if let post = post {
            delegate?.linkTapped(post: post)
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
