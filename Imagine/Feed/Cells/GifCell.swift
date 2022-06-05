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
    @IBOutlet weak var GIFViewHeightConstraint: NSLayoutConstraint!
    
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
        
        guard let playerLayer = avPlayerLayer, let post = post, let imageHeight = post.link?.mediaHeight, let imageWidth = post.link?.mediaWidth else {
            
            return
        }
        let containerWidth = self.contentView.frame.width-10
        
        let ratio = imageWidth / imageHeight
        var newHeight = containerWidth / ratio
        
        if newHeight >= 500 {
            newHeight = 500
        }
        
        playerLayer.frame = CGRect(x: 0, y: 0, width: containerWidth, height: newHeight)
    }
    
    //MARK:- Set Cell
    override func setCell() {
        super.setCell()
        
        if let post = post {
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                
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
    }
    
    //MARK:- GIFPlayer
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
