//
//  BaseFeedCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

enum CellType {
    case ownCell
    case normal
}

class BaseFeedCell : UITableViewCell {
    
    let handyHelper = HandyHelper()
    
    var centerX: NSLayoutConstraint?
    var distanceConstraint: NSLayoutConstraint?
    
    let db = Firestore.firestore()
    
    var cellStyle: CellType?
    var ownProfile: Bool = false
    
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var wowButton: DesignableButton!
    @IBOutlet weak var haButton: DesignableButton!
    @IBOutlet weak var niceButton: DesignableButton!
    @IBOutlet weak var reportButton: DesignableButton!
    @IBOutlet weak var linkedFactButton: UIButton!
    @IBOutlet weak var factImageView: UIImageView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var OPNameLabel: UILabel!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var followTopicImageView: DesignableImage!
    @IBOutlet weak var descriptionPreviewLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    //ReportView
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    
    let buttonLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        label.alpha = 0.8
        
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if ownProfile {
            thanksButton.setImage(nil, for: .normal)
            wowButton.setImage(nil, for: .normal)
            haButton.setImage(nil, for: .normal)
            niceButton.setImage(nil, for: .normal)
        } else {
            thanksButton.setImage(UIImage(named: "thanks"), for: .normal)
            wowButton.setImage(UIImage(named: "wow"), for: .normal)
            haButton.setImage(UIImage(named: "ha"), for: .normal)
            niceButton.setImage(UIImage(named: "nice"), for: .normal)
        }
    }
    
    /// Set the default values for the standard buttons and imageviews
    func initiateCell(thanksButton: DesignableButton, wowButton: DesignableButton, haButton: DesignableButton, niceButton: DesignableButton, factImageView: UIImageView, profilePictureImageView: UIImageView) {
        
        factImageView.layer.cornerRadius = 3
        factImageView.layer.borderWidth = 1
        factImageView.layer.borderColor = UIColor.clear.cgColor
        
        thanksButton.setImage(nil, for: .normal)
        wowButton.setImage(nil, for: .normal)
        haButton.setImage(nil, for: .normal)
        niceButton.setImage(nil, for: .normal)
        
        thanksButton.imageView?.contentMode = .scaleAspectFit
        wowButton.imageView?.contentMode = .scaleAspectFit
        haButton.imageView?.contentMode = .scaleAspectFit
        niceButton.imageView?.contentMode = .scaleAspectFit
        
        if #available(iOS 13.0, *) {
            thanksButton.layer.borderColor = UIColor.secondaryLabel.cgColor
            wowButton.layer.borderColor = UIColor.secondaryLabel.cgColor
            haButton.layer.borderColor = UIColor.secondaryLabel.cgColor
            niceButton.layer.borderColor = UIColor.secondaryLabel.cgColor
        } else {
            thanksButton.layer.borderColor = UIColor.black.cgColor
            wowButton.layer.borderColor = UIColor.black.cgColor
            haButton.layer.borderColor = UIColor.black.cgColor
            niceButton.layer.borderColor = UIColor.black.cgColor
        }
        thanksButton.layer.borderWidth = 0.5
        wowButton.layer.borderWidth = 0.5
        haButton.layer.borderWidth = 0.5
        niceButton.layer.borderWidth = 0.5
        
        print("Initialized")
        
        // Profile Picture
        let layer = profilePictureImageView.layer
        layer.cornerRadius = profilePictureImageView.frame.width/2
    }
    
    ///Set the view above the post: Zero Height if it is normal, if the post is flagged it will show the report reason
    func setReportView(post: Post, reportView: DesignablePopUp, reportLabel: UILabel, reportButton: DesignableButton, reportViewHeightConstraint: NSLayoutConstraint) {
        // Set ReportView
        let reportViewOptions = handyHelper.setReportView(post: post)
        
        reportViewHeightConstraint.constant = reportViewOptions.heightConstant
        reportButton.isHidden = reportViewOptions.buttonHidden
        reportLabel.text = reportViewOptions.labelText
        reportView.backgroundColor = reportViewOptions.backgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let shadowRadius = Constants.Numbers.feedShadowRadius
        let radius = Constants.Numbers.feedCornerRadius
        
        let layer = containerView.layer
        layer.cornerRadius = radius
        if #available(iOS 13.0, *) {
            layer.shadowColor = UIColor.label.cgColor
        } else {
            layer.shadowColor = UIColor.black.cgColor
        }
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = 0.5
        
        let rect = CGRect(x: 0, y: 0, width: contentView.frame.width-20, height: contentView.frame.height-20)
        layer.shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        
    }
    
    override func awakeFromNib() {
        
    }
    
    /// If you look at your own Feed at UserFeedTableView
    func setOwnCell() {
        
        if #available(iOS 13.0, *) {
            thanksButton.backgroundColor = .tertiaryLabel
            wowButton.backgroundColor = .tertiaryLabel
            haButton.backgroundColor = .tertiaryLabel
            niceButton.backgroundColor = .tertiaryLabel
            
        } else {
            thanksButton.backgroundColor = .darkGray
            wowButton.backgroundColor = .darkGray
            haButton.backgroundColor = .darkGray
            niceButton.backgroundColor = .darkGray
            
        }
        
        thanksButton.setTitleColor(.white, for: .normal)
        wowButton.setTitleColor(.white, for: .normal)
        haButton.setTitleColor(.white, for: .normal)
        niceButton.setTitleColor(.white, for: .normal)
        
        thanksButton.layer.borderWidth = 0
        wowButton.layer.borderWidth = 0
        haButton.layer.borderWidth = 0
        niceButton.layer.borderWidth = 0
    }
    
    ///Load the fact and return it asynchroniously
    func loadFact(language: Language, fact: Community, beingFollowed: Bool, completion: @escaping (Community) -> Void) {
        
        if fact.documentID != "" {
            var collectionRef: CollectionReference!
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(fact.documentID)
            ref.getDocument { (doc, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let document = doc {
                        if let data = document.data() {
                            guard let name = data["name"] as? String else {
                                return
                            }
                            let fact = Community()
                            
                            if let displayString = data["displayOption"] as? String {
                                if displayString == "topic" {
                                    fact.displayOption = .topic
                                } else {
                                    fact.displayOption = .fact
                                }
                            }
                            
                            if let postCount = data["postCount"] as? Int {
                                fact.postCount = postCount
                            }
                            
                            if let follower = data["follower"] as? [String] {
                                fact.followerCount = follower.count
                            }
                            
                            if beingFollowed {
                                fact.beingFollowed = true
                            }
                            if let url = data["imageURL"] as? String {
                                fact.imageURL = url
                            }
                            if let description = data["description"] as? String {
                                fact.description = description
                            }
                            if let isAddOnFirstView = data ["isAddOnFirstView"] as? Bool {
                                fact.isAddOnFirstView = isAddOnFirstView
                            }
                            
                            fact.language = language
                            fact.title = name
                            fact.documentID = document.documentID
                            fact.fetchComplete = true
                            
                            completion(fact)
                        }
                    }
                }
            }
        }
    }
    
    func showButtonText(post: Post, button: DesignableButton) {
//        buttonLabel.alpha = 1
//
//        if let _ = centerX {
//            centerX!.isActive = false
//            distanceConstraint!.isActive = false
//        }
        
//        centerX = buttonLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor)
//        centerX!.priority = UILayoutPriority(rawValue: 250)
//        centerX!.isActive = true
//
//        distanceConstraint = buttonLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -45)
//        distanceConstraint!.priority = UILayoutPriority(rawValue: 250)
//        distanceConstraint!.isActive = true
//        self.layoutIfNeeded()
        
        var title = String(post.votes.thanks)
        
        switch button {
        case thanksButton:
//            buttonLabel.text = "danke"
            title = String(post.votes.thanks)
        case wowButton:
//            buttonLabel.text = "wow"
            title = String(post.votes.wow)
        case haButton:
//            buttonLabel.text = "ha"
            title = String(post.votes.ha)
        case niceButton:
//            buttonLabel.text = "nice"
            title = String(post.votes.nice)
        default:
            buttonLabel.text = "so nicht"
        }
        
//        distanceConstraint!.constant = -60
//
//        UIView.animate(withDuration: 1) {
////            self.layoutIfNeeded()
//            self.buttonLabel.alpha = 0
//        }
        
        button.setImage(nil, for: .normal)
        button.setTitle(title, for: .normal)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
}
