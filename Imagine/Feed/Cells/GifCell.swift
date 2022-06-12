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
    
    //MARK:- IBOutlets
    @IBOutlet weak var gifView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var gifViewHeightConstraint: NSLayoutConstraint!
    
    //MARK:- Variables
    private var avPlayer: AVPlayer?
    private var avPlayerLayer: AVPlayerLayer?
        
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        activityIndicatorView.hidesWhenStopped = true
        
        self.initiateCell()
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        gifView.layer.cornerRadius = 8
        gifView.clipsToBounds = true
        gifView.layoutIfNeeded()
        
        setupGIFPlayer()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetValues()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let playerLayer = avPlayerLayer else { return }

        avPlayerLayer?.frame = gifView.bounds
        print("playlay: \(playerLayer.frame), gifview: \(gifView.frame)")
    }
    
    //MARK:- Set Cell
    override func setCell() {
        super.setCell()
        
        guard let post = post else { return }
        
        setViewHeight(for: post)
        
        if ownProfile {
            if let _ = cellStyle {
                print("Already Set")
            } else {
                cellStyle = .ownCell
                setOwnCell(post: post)
            }
        } else {
            setDefaultButtonImages()
        }
        
        if post.user == nil {
            if post.anonym {
                self.setUser()
            } else {
                self.checkForUser()
            }
        } else {
            setUser()
        }
        
        titleLabel.text = post.title
        feedLikeView.setPost(post: post)
        
        
        if let fact = post.community {
            
            if fact.title == "" {
                if fact.beingFollowed {
                    self.getCommunity(beingFollowed: true)
                } else {
                    self.getCommunity(beingFollowed: false)
                }
            } else {
                self.setCommunity(post: post)
            }
        }
        
        setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
    }
    
    func setViewHeight(for post: Post) {
        guard let link = post.link else { return }
        let imageHeight = link.mediaHeight ?? 0
        let imageWidth = link.mediaWidth ?? 0
        
        let ratio = imageWidth / imageHeight
        let width = frame.width - 20  // 5+5 from contentView and 5+5 from inset
        var newHeight = width / ratio
        
        if newHeight >= 500 {
            newHeight = 500
        }
        
        gifViewHeightConstraint.constant = newHeight
    }
    
    //MARK:- GIFPlayer
    func setupGIFPlayer(){
        self.avPlayer = AVPlayer.init(playerItem: self.videoPlayerItem)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = .resizeAspectFill
        avPlayer?.actionAtItemEnd = .none
        avPlayer?.isMuted = true
        avPlayer?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        
        avPlayerLayer?.frame = gifView.bounds
        gifView.layer.addSublayer(avPlayerLayer!)
        
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
    
    
    func stopPlayback(){
        self.avPlayer?.pause()
    }

    func startPlayback(){
        self.avPlayer?.play()
    }
    
    
        
    //To Loop the Video
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
