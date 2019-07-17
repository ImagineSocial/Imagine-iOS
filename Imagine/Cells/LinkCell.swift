//
//  LinkCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SwiftLinkPreview


protocol LinkCellDelegate {
    func linkTapped(post: Post)
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
}

class LinkCell : UITableViewCell {
    
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var ogPosterNameLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var linkThumbNailImageView: UIImageView!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var thanksCountLabel: UILabel!
    @IBOutlet weak var wowCountLabel: UILabel!
    @IBOutlet weak var haCountLabel: UILabel!
    @IBOutlet weak var niceCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
    let handyHelper = HandyHelper()
    
    var delegate: LinkCellDelegate?
    
    var post :Post? {
        didSet {
            if let post = post {
                
                linkThumbNailImageView.image = UIImage(named: "default")
                linkThumbNailImageView.layer.cornerRadius = 3
                
                thanksCountLabel.text = "thanks"
                wowCountLabel.text = "wow"
                haCountLabel.text = "ha"
                niceCountLabel.text = "nice"
                commentCountLabel.text = String(post.commentCount)
                
                // Profile Picture
                let layer = profilePictureImageView.layer
                layer.cornerRadius = profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                createDateLabel.text = post.createTime
                ogPosterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                
                titleLabel.text = post.title
                titleLabel.layoutIfNeeded()
                
                // Preview des Links anzeigen
                slp.preview(post.linkURL, onSuccess: { (result) in
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
            thanksCountLabel.text = String(post.votes.thanks)
        }
    }
    
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            wowCountLabel.text = String(post.votes.wow)
        }
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            haCountLabel.text = String(post.votes.ha)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            niceCountLabel.text = String(post.votes.nice)
        }
    }
    
    @IBAction func reportTapped(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
}
