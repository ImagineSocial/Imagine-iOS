//
//  AddOnPlaylistTrackTableViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.11.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import WebKit

protocol PlaylistTrackDelegate: class {
    func closeWebView()
}

class AddOnPlaylistTrackTableViewCell: UITableViewCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var trackTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumCoverImageView: DesignableImage!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumCoverHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dismissButton: DesignableButton!
    
    //MARK:- Variables
    let postHelper = FirestoreRequest.shared
    
    let defaultAlbumCoverHeight:CGFloat = 50
    
    weak var delegate: PlaylistTrackDelegate?
    
    var track: Post? {
        didSet {
            if let track = track, let songwhip = track.link?.songwhip {
                if let url = URL(string: songwhip.musicImage) {
                    albumCoverImageView.sd_setImage(with: url, completed: nil)
                }
                trackTitleLabel.text = songwhip.title
                artistNameLabel.text = songwhip.artist.name
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        webView.navigationDelegate = self
        webView.layer.cornerRadius = 8
        webView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        webView.navigationDelegate = nil
        dismissButton.isHidden = true
        webViewHeightConstraint.constant = 0
        self.albumCoverHeightConstraint.constant = defaultAlbumCoverHeight
    }
    
    //MARK:- Change UI
    func expandWebView() {
        if let track = track {
            dismissButton.isHidden = false
            webViewHeightConstraint.constant = 350
            UIView.animate(withDuration: 0.6) {
                self.albumCoverHeightConstraint.constant = 40
            }
            
            if let link = track.link, let url = URL(string: link.url) {
                let request = URLRequest(url: url)
                webView.load(request)
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
    
    //MARK:- IBActions
    @IBAction func dismissButtonTapped(_ sender: Any) {
        closeWebView()
        delegate?.closeWebView()
    }
}

//MARK:- WebView Delegate
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
