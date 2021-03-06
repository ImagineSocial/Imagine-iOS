//
//  MusicCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.07.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol MusicPostDelegate {
    func expandView()
}

class MusicCell: BaseFeedCell, WKUIDelegate, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var expandViewButton: DesignableButton!
    @IBOutlet weak var albumPreviewShadowView: UIView!
    @IBOutlet weak var albumPreviewImageView: DesignableImage!
    @IBOutlet weak var musicTitleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var releaseYearLabel: UILabel!
    @IBOutlet weak var musicViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var songwhipButton: UIButton!
    
    var delegate: PostCellDelegate?
    var webViewDelegate: MusicPostDelegate?
    
    var position: CGPoint?
    var webViewFinished = false
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
        
        titleLabel.adjustsFontSizeToFitWidth = true
                
        self.addSubview(buttonLabel)
                
        webView.navigationDelegate = self
        webView.layer.cornerRadius = 8
        webView.clipsToBounds = true
        
        songwhipButton.imageView?.contentMode = .scaleAspectFit
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shadowRadius = Constants.Numbers.feedShadowRadius
        let radius = Constants.Numbers.feedCornerRadius
        
        let musicLayer = albumPreviewShadowView.layer
        let layer = containerView.layer
        
        layer.cornerRadius = radius
        musicLayer.cornerRadius = radius
        
        if #available(iOS 13.0, *) {
            layer.shadowColor = UIColor.label.cgColor
            musicLayer.shadowColor = UIColor.label.cgColor
        } else {
            layer.shadowColor = UIColor.black.cgColor
            musicLayer.shadowColor = UIColor.black.cgColor
        }
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = 0.5
        
        musicLayer.shadowOffset = CGSize.zero
        musicLayer.shadowRadius = 10
        musicLayer.shadowOpacity = 0.3
        
        let rect = CGRect(x: 0, y: 0, width: contentView.frame.width-20, height: contentView.frame.height-20)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        
        let width = contentView.frame.width-140
        let musicRect = CGRect(x: 0, y: 0, width: width, height: width)
        musicLayer.shadowPath = UIBezierPath(roundedRect: musicRect, cornerRadius: radius).cgPath
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        descriptionPreviewLabel.text = nil
        
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
        followTopicImageView.isHidden = true
        
        webViewHeightConstraint.constant = 250
        
//        viewAboveWebView.isHidden = false
        expandViewButton.isHidden = false
        expandViewButton.alpha = 1
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
        
        musicViewHeightConstraint.constant = 400
        webViewHeightConstraint.constant = 0
        albumPreviewImageView.alpha = 1
        albumPreviewShadowView.alpha = 1
        musicTitleLabel.alpha = 1
        artistLabel.alpha = 1
        releaseYearLabel.alpha = 1
        expandViewButton.alpha = 1
        
        albumPreviewImageView.isHidden = false
        albumPreviewShadowView.isHidden = false
        musicTitleLabel.isHidden = false
        artistLabel.isHidden = false
        releaseYearLabel.isHidden = false
        expandViewButton.isHidden = false
        
        
    }
    
    func expandWebView() {
        let height = musicViewHeightConstraint.constant
        
        UIView.animate(withDuration: 0.5) {
            self.musicViewHeightConstraint.constant = 0
            self.webViewHeightConstraint.constant = height
            self.albumPreviewImageView.alpha = 0
            self.albumPreviewShadowView.alpha = 0
            self.musicTitleLabel.alpha = 0
            self.artistLabel.alpha = 0
            self.releaseYearLabel.alpha = 0
            self.expandViewButton.alpha = 0
            
            self.layoutIfNeeded()
        } completion: { (_) in            
            self.webViewDelegate?.expandView()

            self.albumPreviewImageView.isHidden = true
            self.albumPreviewShadowView.isHidden = true
            self.musicTitleLabel.isHidden = true
            self.artistLabel.isHidden = true
            self.releaseYearLabel.isHidden = true
            self.expandViewButton.isHidden = true
            
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url, let host = url.host, !host.hasPrefix("songwhip.com") && !host.hasPrefix("vars.hotjar.com")  {
            
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
        
    }
    
    func getYearFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let stringDate = dateFormatter.string(from: date)
        
        return stringDate
    }
    
    var post: Post? {
        didSet {
            if let post = post {
                
                if let url = URL(string: post.linkURL) {
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
                
                if let music = post.music {
                    if let url = URL(string: music.musicImageURL) {
                        albumPreviewImageView.sd_setImage(with: url, completed: nil)
                    }
                    
                    musicTitleLabel.text = music.name
                    artistLabel.text = music.artist
                    if let releaseDate = music.releaseDate {
                        releaseYearLabel.text = getYearFromDate(date: releaseDate)
                    }
                }
                
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
                
                if post.user.displayName == "" {
                    if post.anonym {
                        self.setUser()
                    } else {
                        self.getName()
                    }
                } else {
                    setUser()
                }
                
                createDateLabel.text = post.createTime
                titleLabel.text = post.title
                descriptionPreviewLabel.text = post.description
                commentCountLabel.text = String(post.commentCount)
                
                
                if let fact = post.fact {
                    if #available(iOS 13.0, *) {
                        self.factImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
                    } else {
                        self.factImageView.layer.borderColor = UIColor.darkGray.cgColor
                    }
                                    
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
                
                setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
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
    

    @IBAction func expandViewButtonTapped(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if webViewHeightConstraint.constant != 500 {
            self.expandWebView()
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
    
    @IBAction func reportPressed(_ sender: Any) {
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

