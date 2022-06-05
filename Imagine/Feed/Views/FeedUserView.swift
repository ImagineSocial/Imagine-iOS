//
//  FeedUserView.swift
//  Imagine
//
//  Created by Malte Schoppe on 15.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol FeedUserViewDelegate: class {
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
    @IBOutlet weak var locationLabel: UILabel!
    
    //Constraints
    @IBOutlet weak var nameLabelLeadingToSuperViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameLabelLeadingToProfilePictureTrailingConstraint: NSLayoutConstraint!
    
    
    //MARK: - Variables
    weak var delegate: FeedUserViewDelegate?
    private var isProfilePictureHidden = false
    
    //MARK: - Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
        
        setUpUI()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    //MARK: - SetUp UI
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
        if isProfilePictureHidden {
            hideProfilePicture()
        }
    }
    
    //MARK: - User
    func setUser(post: Post) {
        
        //check options
        if let options = post.options, options.hideProfilePicture {
            self.isProfilePictureHidden = true
            hideProfilePicture()
        }
        
        //check location
        if let location = post.location {
            locationLabel.text = "in \(location.title)"
        }
        
        createDateLabel.text = post.createDate.formatForFeed()
        if post.anonym {
            if let anonymousName = post.options?.anonymousName {
                nameLabel.text = anonymousName
            } else {
                nameLabel.text = Constants.strings.anonymPosterName
            }
            profilePictureImageView.image = UIImage(named: "anonym-user")
        } else if let user = post.user {
            nameLabel.text = user.displayName
            
            // Profile Picture
            if let urlString = user.imageURL, let url = URL(string: urlString) {
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
    }
    
    //MARK: - LinkedCommunity
    func setCommunity(post: Post) {
        
        self.linkedCommunityImageView.layer.borderColor = UIColor.secondaryLabel.cgColor
        
        if let url = URL(string: post.community!.imageURL) {
            self.linkedCommunityImageView.sd_setImage(with: url, completed: nil)
        } else {
            self.linkedCommunityImageView.backgroundColor = .systemBackground
            self.linkedCommunityImageView.image = UIImage(named: "default-community")
        }
    }
    
    
    //MARK: - Reuse
    func prepareForReuse() {
        //Reset User
        profilePictureImageView.sd_cancelCurrentImageLoad()
        profilePictureImageView.image = nil
        nameLabel.text = ""
        
        //Reset linked COmmunity
        linkedCommunityImageView.layer.borderColor = UIColor.clear.cgColor
        linkedCommunityImageView.image = nil
        linkedCommunityImageView.backgroundColor = .clear
        communityPostImageView.isHidden = true
        
        //reset hideProfilePicture stuff
        profilePictureImageView.isHidden = false
        nameLabelLeadingToProfilePictureTrailingConstraint.isActive = true
        nameLabelLeadingToSuperViewLeadingConstraint.isActive = false
    }
    
    
    
    //MARK: - IBActions
    
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
