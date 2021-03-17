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
    
    //MARK:- IBOutlets
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var wowButton: DesignableButton!
    @IBOutlet weak var haButton: DesignableButton!
    @IBOutlet weak var niceButton: DesignableButton!
    @IBOutlet weak var commentCountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionPreviewLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    //ReportView
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    //User & linked Community
    @IBOutlet weak var feedUserView: FeedUserView!
    
    //MARK:- Variables
    let handyHelper = HandyHelper()
    
    var centerX: NSLayoutConstraint?
    var distanceConstraint: NSLayoutConstraint?
    
    let db = Firestore.firestore()
    
    var cellStyle: CellType?
    var ownProfile: Bool = false
    var delegate: PostCellDelegate?
    
    /// Set this post in the TableViewDataSource to fill the cell with life
    var post:Post? {
        didSet {
            setCell()
        }
    }
    
    //MARK:- Cell Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if ownProfile {
            thanksButton.setImage(nil, for: .normal)
            wowButton.setImage(nil, for: .normal)
            haButton.setImage(nil, for: .normal)
            niceButton.setImage(nil, for: .normal)
        } else {
            thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
            wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
            haButton.setImage(UIImage(named: "haButton"), for: .normal)
            niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
        }
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
    
    //MARK:- Reset Values
    func resetValues() {
        
        //Text
        titleLabel.text = nil
        descriptionPreviewLabel.text = nil
        
        //buttons
        thanksButton.isEnabled = true
        wowButton.isEnabled = true
        haButton.isEnabled = true
        niceButton.isEnabled = true
        
        //feedUserView data
        feedUserView.prepareForReuse()
    }
    
    //MARK:- Initialization
    /// Set the default values for the standard buttons
    func initiateCell() {
        
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        for button in buttons {
            button.setImage(nil, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.layer.borderWidth = 0.5
            
            if #available(iOS 13.0, *) {
                button.layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                button.layer.borderColor = UIColor.black.cgColor
            }
        }
    }
    
    /// If you look at your own Feed at UserFeedTableView
    func setOwnCell(post: Post) {
        
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        for button in buttons {
            
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
            
            if #available(iOS 13.0, *) {
                button.backgroundColor = .tertiaryLabel
            } else {
                button.backgroundColor = .darkGray
            }
        }
        
        //Set vote count
        thanksButton.setTitle(String(post.votes.thanks), for: .normal)
        wowButton.setTitle(String(post.votes.wow), for: .normal)
        haButton.setTitle(String(post.votes.ha), for: .normal)
        niceButton.setTitle(String(post.votes.nice), for: .normal)
    }
    
    func setDefaultButtonImages() {
        thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
        wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
        haButton.setImage(UIImage(named: "haButton"), for: .normal)
        niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
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
    
    //MARK:- SetCell
    /// Set the desired functions and layout for the cell
    /// Set the FeedUserDelegate here, so the buttons in the user view are connected
    func setCell() {
        
    }
    
    //MARK:- Get Community
    ///Load the fact and return it asynchroniously
    func getCommunity(language: Language, community: Community, beingFollowed: Bool, completion: @escaping (Community) -> Void) {
        
        if community.documentID != "" {
            var collectionRef: CollectionReference!
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(community.documentID)
            ref.getDocument { (doc, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let document = doc {
                        if let data = document.data() {
                            let communityHelper = CommunityHelper()
                            let user = Auth.auth().currentUser
                            
                            if let community = communityHelper.getCommunity(currentUser: user, documentID: document.documentID, data: data) {
                                completion(community)
                            } else {
                                print("Error: COuldnt get a community")
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK:- User
    var index = 0
    func getUser() {
        if index < 20 {
            if let post = self.post {
                if post.user.displayName == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getUser()
                        self.index+=1
                    }
                } else {
                    setUser()
                }
            }
        }
    }
    
    func setUser() {
        if let post = post {
            feedUserView.setUser(post: post)
        }
    }
    
    //MARK:- Community
    func getCommunity(beingFollowed: Bool) {
        if let post = post, let fact = post.fact {
            self.getCommunity(language: post.language, community: fact, beingFollowed: beingFollowed) {
                (fact) in
                post.fact = fact
                
                self.setCommunity(post: post)
            }
        }
    }
    
    func setCommunity(post: Post) {
        feedUserView.setCommunity(post: post)
    }
    
    //MARK:- Set Vote Button Title
    func registerVote(post: Post, button: DesignableButton) {
        
        var title = String(post.votes.thanks)
        
        switch button {
        case thanksButton:
            title = String(post.votes.thanks)
            thanksButton.isEnabled = false
            delegate?.thanksTapped(post: post)
            post.votes.thanks = post.votes.thanks+1
        case wowButton:
            wowButton.isEnabled = false
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            title = String(post.votes.wow)
        case haButton:
            haButton.isEnabled = false
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            title = String(post.votes.ha)
        case niceButton:
            niceButton.isEnabled = false
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            title = String(post.votes.nice)
        default:
            title = String(post.votes.thanks)
        }
        
        button.setImage(nil, for: .normal)
        button.setTitle(title, for: .normal)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
}

extension BaseFeedCell: FeedUserViewDelegate {
    
    func reportButtonTapped() {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
    func userButtonTapped() {
        if let post = post {
            if !post.anonym {
                delegate?.userTapped(post: post)
            }
        }
    }
    
    func linkedCommunityButtonTapped() {
        if let fact = post?.fact {
            delegate?.factTapped(fact: fact)
        }
    }
}
