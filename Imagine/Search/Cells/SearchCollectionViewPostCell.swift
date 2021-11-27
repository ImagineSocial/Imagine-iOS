//
//  SearchCollectionViewPostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import AVKit

class SearchCollectionViewPostCell: UICollectionViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var searchCellImageView: UIImageView!
    @IBOutlet weak var SearchCellMultiPictureIcon: UIImageView!
    
    //MARK:- Variables
    
    var post: Post? {
        didSet {
            if let post = post {
                if post.type == .picture {
                    
                    if let thumbnailURL = post.thumbnailImageURL, let url = URL(string: thumbnailURL) {
                        searchCellImageView.sd_setImage(with: url, completed: nil)
                    } else if let url = URL(string: post.imageURL) {
                        searchCellImageView.sd_setImage(with: url, completed: nil)
                    }
                } else if post.type == .GIF {
                    avPlayerLayer?.removeFromSuperlayer()
                    GIFLink = post.linkURL
                } else if post.type == .multiPicture {
                    if let images = post.imageURLs {
                        if let url = URL(string: images[0]) {
                            searchCellImageView.sd_setImage(with: url, completed: nil)
                        }
                    }
                    SearchCellMultiPictureIcon.isHidden = false
                }
            }
        }
    }
    var avPlayer: AVPlayer? {
        didSet {
            avPlayer?.actionAtItemEnd = .none
            avPlayer?.isMuted = true
            avPlayer?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        }
    }
    var avPlayerLayer: AVPlayerLayer? {
        didSet {
            
            avPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            self.searchCellImageView.layer.addSublayer(avPlayerLayer!)
        }
    }
    
    var videoPlayerItem: AVPlayerItem? {
        didSet {
            avPlayer?.replaceCurrentItem(with: self.videoPlayerItem)
            avPlayer?.play()
        }
    }
    
    var GIFLink: String? {
        didSet {
            print("SetGiFLink")
            
            self.searchCellImageView.image = nil
            
            if avPlayer == nil && avPlayerLayer == nil {
                self.avPlayer = AVPlayer(playerItem: self.videoPlayerItem)
                self.avPlayerLayer = AVPlayerLayer(player: avPlayer)
            }
            
            
            //To Loop the Video
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerItemDidReachEnd(notification:)),
                                                   name: .AVPlayerItemDidPlayToEndTime,
                                                   object: avPlayer?.currentItem)
            
            if let url = URL(string: GIFLink!) {
                if self.videoPlayerItem == nil {
                    self.videoPlayerItem = AVPlayerItem.init(url: url)
                    self.startPlayback()
                } else {
                    print("Already go a VideoPlayerItem")
                }
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let playerLayer = avPlayerLayer {
            
            let containerWidth = self.contentView.frame.width
            
            playerLayer.frame = CGRect(x: 0, y: 0, width: containerWidth, height: containerWidth)
            
        }
    }
    
    override func prepareForReuse() {
        searchCellImageView.image = nil
        avPlayerLayer?.removeFromSuperlayer()
        
        SearchCellMultiPictureIcon.isHidden = true
    }
    
    //MARK:- GIF Player
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                //??
                DispatchQueue.main.async {
                    if newStatus == .playing || newStatus == .paused {
                    } else {
                    }
                }
            }
        }
    }
    
    //To Loop the Video
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    func stopPlayback(){
        self.avPlayer?.pause()
    }

    func startPlayback(){
        self.avPlayer?.play()
    }
}
