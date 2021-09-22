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
    
    //MARK:- IBOutlets
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
        
        let shadowRadius = Constants.Numbers.feedShadowRadius
        let radius = Constants.Numbers.feedCornerRadius
        
        let musicLayer = albumPreviewShadowView.layer
        let layer = containerView.layer
        
        layer.cornerRadius = radius
        musicLayer.cornerRadius = radius
        
        layer.shadowColor = UIColor.label.cgColor
        musicLayer.shadowColor = UIColor.label.cgColor
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
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getUser()
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
    
    func getYearFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let stringDate = dateFormatter.string(from: date)
        
        return stringDate
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

