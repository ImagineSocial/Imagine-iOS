//
//  BaseFeedCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

enum CellType {
    case ownCell
    case normal
}

class BaseFeedCell : UITableViewCell {
    
    //MARK:- IBOutlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    //ReportView
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportViewLabel: UILabel!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewButtonInTop: DesignableButton!
    //User & linked Community
    @IBOutlet weak var feedUserView: FeedUserView!
    //Like Buttons
    
    @IBOutlet weak var feedLikeView: FeedLikeView!
    
    //MARK:- Variables
    private let handyHelper = HandyHelper.shared
    
    var centerX: NSLayoutConstraint?
    var distanceConstraint: NSLayoutConstraint?
    
    private let db = FirestoreRequest.shared.db
    private let communityRequest = CommunityRequest()
    
    var cellStyle: CellType?
    var ownProfile: Bool = false
    weak var delegate: PostCellDelegate?
    
    /// Set this post in the TableViewDataSource to fill the cell with life
    var post: Post? {
        didSet {
            setCell()
        }
    }
    
    //MARK:- Cell Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        feedLikeView.prepareForReuse(ownProfile: ownProfile)
        feedUserView.locationLabel.text = ""
        contentView.clipsToBounds = false
        clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        contentView.clipsToBounds = false
        clipsToBounds = false
        
        let layer = containerView.layer
        layer.createStandardShadow(with: CGSize(width: contentView.frame.width - 24, height: contentView.frame.height - 24), cornerRadius: Constants.Numbers.feedCornerRadius)
    }
    
    //MARK:- Reset Values
    func resetValues() {
        
        //Text
        titleLabel.text = nil
        
        //buttons
        feedLikeView.resetValues()
        
        //feedUserView data
        feedUserView.prepareForReuse()
    }
    
    //MARK:- Initialization
    /// Set the default values for the standard buttons
    func initiateCell() {
        
        //Nichts Ansonsten explicit callen likeView.setConstraints
    }
    
    /// If you look at your own Feed at UserFeedTableView
    func setOwnCell(post: Post) {
        
        feedLikeView.setOwnCell(post: post)
    }
    
    func setDefaultButtonImages() {
        feedLikeView.setDefaultButtonImages()
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
    
    //MARK: - SetCell
    /// Set the desired functions and layout for the cell
    /// Set the FeedUserDelegate here, so the buttons in the user view are connected
    func setCell() {
        feedUserView.delegate = self
        feedLikeView.delegate = self
    }
    
    
    //MARK: - User
    var index = 0
    func checkForUser() {
        if index < 20 {
            if let post = self.post {
                if post.user == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.checkForUser()
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
    
    
    //MARK: - Get Community
    ///Load the fact and return it asynchroniously
    func getCommunity(beingFollowed: Bool) {
        if let post = post, let community = post.community {
            if community.documentID != "" {
                communityRequest.getCommunity(language: post.language, community: community, beingFollowed: beingFollowed) { (community) in
                    
                    post.community = community
                    
                    self.setCommunity(post: post)
                }
            }
        }
    }
    
    func getCommunity() {
        guard let post = post, let communityID = post.communityID else {
            return
        }

        let reference = FirestoreReference.documentRef(.communities, documentID: communityID)
        
        
    }
    
    //MARK:- Set Community
    func setCommunity(post: Post) {
        feedUserView.setCommunity(post: post)
    }
}

//MARK:- FeedUserView Delegate
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
        if let fact = post?.community {
            delegate?.factTapped(fact: fact)
        }
    }
}

//MARK:- FeedLikeView Delegate

extension BaseFeedCell: FeedLikeViewDelegate {
    
    func registerVote(for type: VoteType) {
        post?.registerVote(for: type)
        feedLikeView.showButtonInteraction(type: type, post: post)
    }
}
