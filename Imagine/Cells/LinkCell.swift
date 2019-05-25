//
//  LinkCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol LinkCellDelegate {
    func linkTapped(post: Post)
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
    
    var postObject: Post!
    var delegate: LinkCellDelegate?
    
    func setPost(post: Post) {
        postObject = post
    }
    
    @IBAction func linkTapped(_ sender: Any) {
        delegate?.linkTapped(post: postObject)
    }
}
