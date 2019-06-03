//
//  RepostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol RepostCellDelegate {
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
}

class RePostCell : UITableViewCell {
    
    var delegate: RepostCellDelegate?
    
    @IBOutlet weak var translatedTitleLabel: UILabel!
    @IBOutlet weak var OGPostView: DesignablePopUp!
    @IBOutlet weak var originalCreateDateLabel: UILabel!
    @IBOutlet weak var originalTitleLabel: UILabel!
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportViewButton: DesignableButton!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var ogPosterNameLabel: UILabel!
    @IBOutlet weak var reposterNameLabel: UILabel!
    @IBOutlet weak var repostDateLabel: UILabel!
    @IBOutlet weak var reposterProfilePictureImageView: UIImageView!
    @IBOutlet weak var thanksCountLabel: UILabel!
    @IBOutlet weak var wowCountLabel: UILabel!
    @IBOutlet weak var haCountLabel: UILabel!
    @IBOutlet weak var niceCountLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    var postObject: Post!
    
    func setPost(post: Post) {
        postObject = post
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        delegate?.reportTapped(post: postObject)
    }
    @IBAction func thanksButtonTapped(_ sender: Any) {
        delegate?.thanksTapped(post: postObject)
        postObject.votes.thanks = postObject.votes.thanks+1
        thanksCountLabel.text = String(postObject.votes.thanks)
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        delegate?.wowTapped(post: postObject)
        postObject.votes.wow = postObject.votes.wow+1
        wowCountLabel.text = String(postObject.votes.wow)
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        delegate?.haTapped(post: postObject)
        postObject.votes.ha = postObject.votes.ha+1
        haCountLabel.text = String(postObject.votes.ha)
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        delegate?.niceTapped(post: postObject)
        postObject.votes.nice = postObject.votes.nice+1
        niceCountLabel.text = String(postObject.votes.nice)
    }
    
    
    
}


