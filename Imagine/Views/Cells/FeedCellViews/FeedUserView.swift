//
//  FeedUserView.swift
//  Imagine
//
//  Created by Malte Schoppe on 15.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol FeedUserViewDelegate {
    func reportButtonTapped()
    func userButtonTapped()
    func linkedCommunityButtonTapped()
}

@IBDesignable
class FeedUserView: UIView, NibLoadable {
    
    //MARK:- IBOutlets
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var linkedCommunityImageView: UIImageView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var communityPostImageView: DesignableImage!
    @IBOutlet weak var linkedCommunityButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var menuButton: DesignableButton!
    
    //Constraints
    @IBOutlet weak var nameLabelLeadingToSuperViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabelLeadingToProfilePictureTrailingConstraint: NSLayoutConstraint!
    
    
    //MARK:- Variables
    var delegate: FeedUserViewDelegate?
    
    //MARK:- Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        
        setUpUI()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    //MARK:- SetUp UI
    func setUpUI() {
        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
        
        linkedCommunityImageView.layer.cornerRadius = 3
        linkedCommunityImageView.layer.borderWidth = 1
        linkedCommunityImageView.layer.borderColor = UIColor.clear.cgColor
    }
    
    /// We need to check if the view will enter the foreground again after the user moved it to the background because the unchecked "installed" constraint from the nameLabelLeadingToSuperViewLeadingCOnstraint
    @objc func willEnterForeground() {
        
        hideProfilePicture()
    }
    
    //MARK:- User
    func setUser(post: Post) {
        
        //just for testing
        if post.user.displayName == "Malte Schoppe" {
            hideProfilePicture()
        }
        
        createDateLabel.text = post.createTime
        if post.anonym {
            if let anonymousName = post.anonymousName {
                nameLabel.text = anonymousName
            } else {
                nameLabel.text = Constants.strings.anonymPosterName
            }
            profilePictureImageView.image = UIImage(named: "anonym-user")
        } else {
            nameLabel.text = post.user.displayName
            
            // Profile Picture
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            } else {
                profilePictureImageView.image = UIImage(named: "default-user")
            }
        }
    }
    
    private func hideProfilePicture() {
        profilePictureImageView.isHidden = true
        nameLabelLeadingToProfilePictureTrailingConstraint.isActive = false
        nameLabelLeadingToSuperViewLeadingConstraint.isActive = true
        nameLabel.font = UIFont(name: "IBMPlexSans-Medium", size: 12)
    }
    
    //MARK:- LinkedCommunity
    func setCommunity(post: Post) {
        
        if #available(iOS 13.0, *) {
            self.linkedCommunityImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
        } else {
            self.linkedCommunityImageView.layer.borderColor = UIColor.darkGray.cgColor
        }
        
        if post.isTopicPost {
            communityPostImageView.isHidden = false
        }
        
        if let url = URL(string: post.fact!.imageURL) {
            self.linkedCommunityImageView.sd_setImage(with: url, completed: nil)
        } else {
            if #available(iOS 13.0, *) {
                self.linkedCommunityImageView.backgroundColor = .systemBackground
            } else {
                self.linkedCommunityImageView.backgroundColor = .white
            }
            self.linkedCommunityImageView.image = UIImage(named: "FactStamp")
        }
    }
    
    
    //MARK:- Reuse
    func prepareForReuse() {
        //Reset User
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        
        //Reset linked COmmunity
        linkedCommunityImageView.layer.borderColor = UIColor.clear.cgColor
        linkedCommunityImageView.image = nil
        linkedCommunityImageView.backgroundColor = .clear
        communityPostImageView.isHidden = true
        
        //reset hideProfilePicture stuff
        profilePictureImageView.isHidden = false
        nameLabelLeadingToProfilePictureTrailingConstraint.isActive = true
        nameLabelLeadingToSuperViewLeadingConstraint.isActive = false
        nameLabel.font = UIFont(name: "IBMPlexSans", size: 12)
    }
    
    //MARK:- IBActions
    
    @IBAction func reportPressed(_ sender: Any) {
        delegate?.reportButtonTapped()
    }
    
    
    @IBAction func userButtonTapped(_ sender: Any) {
        delegate?.userButtonTapped()
    }
    
    @IBAction func linkedCommunityButtonTapped(_ sender: Any) {
        delegate?.linkedCommunityButtonTapped()
    }
}
