//
//  AddOnPlaylistTrackTableViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.11.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import WebKit

protocol PlaylistTrackDelegate {
    func closeWebView()
}

class AddOnPlaylistTrackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumCoverImageView: DesignableImage!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumCoverHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dismissButton: DesignableButton!
    
    let postHelper = FirestoreRequest()
    
    let defaultAlbumCoverHeight:CGFloat = 50
    
    var delegate: PlaylistTrackDelegate?
    
    var track: Post? {
        didSet {
            if let track = track {
                if let music = track.music {
                    if let url = URL(string: music.musicImageURL) {
                        albumCoverImageView.sd_setImage(with: url, completed: nil)
                    }
                    trackTitleLabel.text = music.name
                    artistNameLabel.text = music.artist
                } 
            }
        }
    }
    
    override func awakeFromNib() {
        webView.navigationDelegate = self
        webView.layer.cornerRadius = 8
        webView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        dismissButton.isHidden = true
        webViewHeightConstraint.constant = 0
        self.albumCoverHeightConstraint.constant = defaultAlbumCoverHeight
    }
    
    func expandWebView() {
        if let track = track {
            dismissButton.isHidden = false
            webViewHeightConstraint.constant = 350
            UIView.animate(withDuration: 0.6) {
                self.albumCoverHeightConstraint.constant = 40
            }
            if let music = track.music {
                if let url = URL(string: music.songwhipURL) {
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
            }
        }
    }
    
    func closeWebView() {
        
        dismissButton.isHidden = true
        albumCoverImageView.alpha = 0
        trackTitleLabel.alpha = 0
        artistNameLabel.alpha = 0
        
        self.webViewHeightConstraint.constant = 0
        self.albumCoverHeightConstraint.constant = self.defaultAlbumCoverHeight
       
        UIView.animate(withDuration: 0.6) {
            self.layoutIfNeeded()
            self.albumCoverImageView.alpha = 1
            self.trackTitleLabel.alpha = 1
            self.artistNameLabel.alpha = 1
        } completion: { (_) in
            UIView.animate(withDuration: 0.3) {
                
            }
        }
    }
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        closeWebView()
        delegate?.closeWebView()
    }
}

extension AddOnPlaylistTrackTableViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url, let host = url.host, !host.hasPrefix("songwhip.com") && !host.hasPrefix("vars.hotjar.com")  {
            
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
        
    }
}
