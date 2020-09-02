//
//  GifCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import Foundation
import UIKit
import AVKit

class GifCell: BaseFeedCell {
    
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var gifView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    
    var delegate: PostCellDelegate?
    
    override func awakeFromNib() {
        selectionStyle = .none
        
        activityIndicatorView.hidesWhenStopped = true
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        self.addSubview(buttonLabel)
        
        
        
        gifView.layer.cornerRadius = 8
        gifView.clipsToBounds = true
        gifView.layoutIfNeeded()
        
        setupGIFPlayer()
    }
    
    func setupGIFPlayer(){
        self.avPlayer = AVPlayer.init(playerItem: self.videoPlayerItem)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avPlayer?.actionAtItemEnd = .none
        avPlayer?.isMuted = true
        avPlayer?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        
        
//        avPlayerLayer?.frame = self.bounds
        self.gifView.layer.addSublayer(avPlayerLayer!)
        
        //To Loop the Video
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer?.currentItem)
    }
    
    var videoPlayerItem: AVPlayerItem? = nil {
        didSet {
            avPlayer?.replaceCurrentItem(with: self.videoPlayerItem)
            avPlayer?.play()
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                DispatchQueue.main.async {[weak self] in
                    if newStatus == .playing || newStatus == .paused {
                        self?.activityIndicatorView.stopAnimating()
                    } else {
                        self?.activityIndicatorView.startAnimating()
                    }
                }
            }
        }
    }
    
    
    var post: Post? {
        didSet {
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
                commentCountLabel.text = String(post.commentCount)
                
                // LabelHeight calculated by the number of letters
                let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                titleLabelHeightConstraint.constant = labelHeight
                
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
                // ToDo: ReportView
            }
        }
    }
    
    func getFact(beingFollowed: Bool) {
        if let post = post {
            if let fact = post.fact {
                self.loadFact(fact: fact, beingFollowed: beingFollowed) {
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
    
    func stopPlayback(){
        self.avPlayer?.pause()
    }

    func startPlayback(){
        self.avPlayer?.play()
    }
    
    override func prepareForReuse() {
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        factImageView.layer.borderColor = UIColor.clear.cgColor
        factImageView.image = nil
        factImageView.backgroundColor = .clear
        followTopicImageView.isHidden = true
        
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let playerLayer = avPlayerLayer {
            
            if let post = post {
                let imageHeight = post.mediaHeight
                let imageWidth = post.mediaWidth
                
                let containerWidth = self.contentView.frame.width-10
                
                let ratio = imageWidth / imageHeight
                var newHeight = containerWidth / ratio
                
                if newHeight >= 500 {
                    newHeight = 500
                }
                
                playerLayer.frame = CGRect(x: 0, y: 0, width: containerWidth, height: newHeight)
            }
        }
    }
        
    //To Loop the Video
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
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
