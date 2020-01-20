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
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var linkThumbNailImageView: UIImageView!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlLabel: UILabel!
    
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.addSubview(buttonLabel)
        buttonLabel.textColor = .black
        
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
        
        linkThumbNailImageView.layer.cornerRadius = 4
        
        factImageView.layer.cornerRadius = 3
        factImageView.layer.borderWidth = 1
        factImageView.layer.borderColor = UIColor.clear.cgColor

        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        titleLabel.layoutIfNeeded()
        
        // add corner radius on `contentView`
        contentView.layer.cornerRadius = 8
//        backgroundColor =  Constants.backgroundColorForTableViews
        backgroundColor = .clear
//        contentView.backgroundColor = Constants.imagineColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        urlLabel.text = nil
        linkThumbNailImageView.sd_cancelCurrentImageLoad()
        linkThumbNailImageView.image = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
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
                thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
                wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
                haButton.setImage(UIImage(named: "haButton"), for: .normal)
                niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
            }
            
            commentCountLabel.text = String(post.commentCount)
            
            // Profile Picture
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
    
    @IBAction func linkedFactTapped(_ sender: Any) {
        if let fact = post?.fact {
            delegate?.factTapped(fact: fact)
        }
    }    
}
