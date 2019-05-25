//
//  RepostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class RePostCell : UITableViewCell {
    
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
    
    @IBAction func moreTapped(_ sender: Any) {
    }
    
    
}


