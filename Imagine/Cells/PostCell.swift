//
//  PostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol PostCellDelegate {
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
}

class PostCell : UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var reportButton: DesignableButton!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    @IBOutlet weak var cellCreateDateLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var ogPosterLabel: UILabel!
    @IBOutlet weak var thanksCountLabel: UILabel!
    @IBOutlet weak var wowCountLabel: UILabel!
    @IBOutlet weak var haCountLabel: UILabel!
    @IBOutlet weak var niceCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    let imageCache = NSCache<NSString, UIImage>()
    let handyHelper = HandyHelper()
    
    var delegate: PostCellDelegate?
    
    // Maybe awake from nib for the UI Layout????
    
    var post:Post? {
        didSet {
            
            // Set to nil in case of non existing stuff
            cellImageView.image = nil
            profilePictureImageView.image = UIImage(named: "default-user")
            titleLabel.text = nil
            
            if let post = post {
                
                titleLabel.text = post.title
                titleLabel.adjustsFontSizeToFitWidth = true
                
                thanksCountLabel.text = "thanks"
                wowCountLabel.text = "wow"
                haCountLabel.text = "ha"
                niceCountLabel.text = "nice"
                commentCountLabel.text = String(post.commentCount)
                
                
                ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
                cellCreateDateLabel.text = post.createTime
                
                // LabelHeight calculated by the number of letters
                let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                titleLabelHeightConstraint.constant = labelHeight
                
                // Profile Picture
                let layer = profilePictureImageView.layer
                layer.cornerRadius = profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                if let cachedImage = imageCache.object(forKey: post.imageURL as NSString) {
                    cellImageView.image = cachedImage  // Using cached Image
                } else {
                    if let url = URL(string: post.imageURL) {   // Load and Cache Image
                        if let cellImageView = cellImageView {
                            
                            cellImageView.isHidden = false      // Check ich nicht, aber geht!
                            cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: []) { (image, err, _, _) in
                                if let image = image {
                                    self.imageCache.setObject(image, forKey: post.imageURL as NSString)
                                }
                            }
                            cellImageView.layer.cornerRadius = 1
                        }
                    }
                    
                    
                }
                
                // Set ReportView
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
    
    @IBAction func reportPressed(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
}
