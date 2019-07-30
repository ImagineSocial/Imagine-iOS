//
//  ThoughtCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 26.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol ThoughtCellDelegate {
    func userTapped(post: Post)
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
}

class ThoughtCell : UITableViewCell {
    
    
    @IBOutlet weak var profilePictureImageView : UIImageView!
    @IBOutlet weak var ogPosterLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var thanksCountLabel: UILabel!
    @IBOutlet weak var wowCountLabel: UILabel!
    @IBOutlet weak var haCountLabel: UILabel!
    @IBOutlet weak var niceCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    var delegate: ThoughtCellDelegate?
    let handyHelper = HandyHelper()
    
    override func awakeFromNib() {
        titleLabel.sizeToFit()
        
        //Profile Picture
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = profilePictureImageView.frame.width/2
        layer.borderWidth = 0.1
        layer.borderColor = UIColor.black.cgColor
    }
    
    var post:Post? {
        didSet {
            if let post = post {
                
                titleLabel.text = nil
                profilePictureImageView.image = UIImage(named: "default-user")
                
                titleLabel.text = post.title
                
                
                thanksCountLabel.text = "thanks"
                wowCountLabel.text = "wow"
                haCountLabel.text = "ha"
                niceCountLabel.text = "nice"
                commentCountLabel.text = String(post.commentCount)
                
                createDateLabel.text = post.createTime
                ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
                
                // Profile Picture
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, completed: nil)
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
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let post = post {
            delegate?.userTapped(post: post)
        }
    }
    
    
}
