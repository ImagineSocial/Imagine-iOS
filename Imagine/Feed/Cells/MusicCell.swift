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

protocol MusicPostDelegate: class {
    func expandView()
}

class MusicCell: BaseFeedCell, WKUIDelegate, WKNavigationDelegate {
    
    static var identifier = "MusicCell"
    
    //MARK: - IBOutlets
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
    
    //MARK:- Variables
    weak var musicPostDelegate: MusicPostDelegate?
    
    private var position: CGPoint?
    private var webViewFinished = false
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        webView.navigationDelegate = self   // should deinit it to avoid memory leak
        webView.layer.cornerRadius = 8
        webView.clipsToBounds = true
        
        songwhipButton.imageView?.contentMode = .scaleAspectFit
        
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        let layer = containerView.layer
        layer.createStandardShadow(with: CGSize(width: contentView.frame.width - 24, height: contentView.frame.height - 24), cornerRadius: Constants.Numbers.feedCornerRadius)
        
        let radius = Constants.Numbers.feedCornerRadius
        
        let musicLayer = albumPreviewShadowView.layer
        
        musicLayer.cornerRadius = radius
        musicLayer.shadowColor = UIColor.label.cgColor
        musicLayer.shadowOffset = CGSize.zero
        musicLayer.shadowRadius = 10
        musicLayer.shadowOpacity = 0.3
        
        let width = contentView.frame.width - 140
        let musicRect = CGRect(x: 0, y: 0, width: width, height: width)
        musicLayer.shadowPath = UIBezierPath(roundedRect: musicRect, cornerRadius: radius).cgPath
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        webViewHeightConstraint.constant = 250
        webView.navigationDelegate = nil
        
        expandViewButton.isHidden = false
        expandViewButton.alpha = 1
        
        
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
        
        resetValues()
    }
    
    //MARK:- Set Cell
    override func setCell() {
        super.setCell()
        
        guard let post = post else {
            return
        }
        if let linkURL = post.link?.url, let url = URL(string: linkURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        setupSongwhip(post.link?.songwhip)
        
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
        
        
        if let communityID = post.communityID {
            if post.community != nil {
                setCommunity(for: post)
            } else {
                getCommunity(with: communityID)
            }
        }
        
        setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
    }
    
    private func setupSongwhip(_ songwhip: Songwhip?) {
        guard let songwhip = songwhip else { return }
        
        if let url = URL(string: songwhip.musicImage) {
            albumPreviewImageView.sd_setImage(with: url, completed: nil)
        }
        
        musicTitleLabel.text = songwhip.artist.name
        artistLabel.text = songwhip.artist.name
        releaseYearLabel.text = songwhip.releaseDate.year()
    }
    
    //MARK:- Animate Web View
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
            self.musicPostDelegate?.expandView()
            
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
    
    
    //MARK:- IBActions
    @IBAction func expandViewButtonTapped(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if webViewHeightConstraint.constant != 500 {
            self.expandWebView()
        }
    }
    
}

