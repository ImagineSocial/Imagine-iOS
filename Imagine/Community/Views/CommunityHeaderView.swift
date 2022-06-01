//
//  CommunityHeaderView.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol CommunityHeaderDelegate: class {
    func segmentedControlTapped(index: Int, direction: UIPageViewController.NavigationDirection)
    func newPostTapped()
    func notLoggedIn()
}

class CommunityHeaderView: UIView {
    
    // MARK: - Variables
    
    static let identifier = "CommunityHeaderView"
    
    weak var delegate: CommunityHeaderDelegate?
    
    let db = FirestoreRequest.shared.db
    
    var community: Community? {
        didSet {
            guard let community = community else { return }
            
            setCommunity(community)
        }
    }
    
    // MARK: - Elements
    
    let imageView = BaseImageView(image: nil, contentMode: .scaleAspectFill)
    let moveImage = BaseImageView(image: Icons.move, tintColor: .secondaryLabel)
    let titleLabel = BaseLabel(font: .standard(with: .semibold, size: 24))
    let descriptionLabel = BaseTextLabel(font: .standard(size: 14))
    let newPostButton = BaseButtonWithImage(image: Icons.newPostIcon)
    let segmentedControlView = BaseSegmentedControlView(items: [Strings.topics, Strings.feed], font: .standard(with: .medium, size: 14))
    let followButton = BaseButtonWithText(text: "Follow", font: .standard(with: .medium, size: 14), borderColor: nil)
    let followerCountLabel = BaseLabel(textColor: .secondaryLabel, font: .standard(size: 12))
    let postCountLabel = BaseLabel(textColor: .secondaryLabel, font: .standard(size: 12))
    
    lazy var countStackView = BaseStackView(subviews: [followerCountLabel, postCountLabel], spacing: 2, axis: .vertical, distribution: .fill)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        imageView.clipsToBounds = true
        backgroundColor = .systemBackground
        
        setupConstraints()
        segmentedControlView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        if #available(iOS 15.0, *) {
            
        } else {
            followButton.cornerRadius = followButton.frame.width / 2
        }
    }
    
    private func setupConstraints() {
        addSubview(imageView)
        addSubview(moveImage)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(segmentedControlView)
        addSubview(followButton)
        addSubview(newPostButton)
        addSubview(countStackView)
        
        let padding = Constants.padding.standard
        
        imageView.constrain(top: topAnchor, leading: leadingAnchor, trailing: trailingAnchor, height: 175)
        moveImage.constrain(top: topAnchor, trailing: trailingAnchor, paddingTop: padding, paddingTrailing: -padding, width: 30, height: 30)
        titleLabel.constrain(top: imageView.bottomAnchor, leading: leadingAnchor, paddingTop: 10, paddingLeading: padding)
        newPostButton.constrain(centerY: titleLabel.centerYAnchor, leading: titleLabel.trailingAnchor, trailing: trailingAnchor, paddingLeading: padding, paddingTrailing: -padding, width: 20, height: 20)
        descriptionLabel.constrain(top: titleLabel.bottomAnchor, leading: titleLabel.leadingAnchor, trailing: trailingAnchor, paddingTop: 5, paddingTrailing: -padding)
        countStackView.constrain(top: descriptionLabel.bottomAnchor, leading: titleLabel.leadingAnchor, paddingTop: 10)
        followButton.constrain(bottom: countStackView.bottomAnchor, trailing: descriptionLabel.trailingAnchor)
        segmentedControlView.constrain(top: countStackView.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, paddingTop: 20, paddingBottom: -10, height: 30)
        
        followButton.addTarget(self, action: #selector(followButtonTapped), for: .touchUpInside)
        newPostButton.addTarget(self, action: #selector(newPostButtonTapped), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.tinted()
            configuration.titlePadding = 5
            configuration.buttonSize = .small
            configuration.cornerStyle = .capsule
            configuration.baseBackgroundColor = .imagineColor
            
            followButton.configuration = configuration
        } else {
            followButton.layer.borderColor = UIColor.label.cgColor
            followButton.layer.borderWidth = 1
            followButton.titleEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        }
    }
    
    private func setCommunity(_ community: Community) {
        if let url = URL(string: community.imageURL) {
            imageView.sd_setImage(with: url, completed: nil)
        } else {
            imageView.image = UIImage(named: "default-community")
        }
        
        if community.beingFollowed {
            followButton.setTitle("Unfollow", for: .normal)
        }
        
        descriptionLabel.text = community.description
        titleLabel.text = community.title
        
        self.followerCountLabel.text = "Follower: \(community.followerCount)"
        self.postCountLabel.text = "Posts: \(community.postCount)"
    }
    
    @objc func followButtonTapped() {
        guard let community = community else { return }
        
        if let _ = Auth.auth().currentUser {
            self.followButton.isEnabled = false
            if community.beingFollowed {
                unfollowTopic(community: community)
            } else {
                followTopic(community: community)
            }
        } else {
            delegate?.notLoggedIn()
        }
    }
    
    @objc func newPostButtonTapped() {
        delegate?.newPostTapped()
    }
    
    func followTopic(community: Community) {
        if let user = Auth.auth().currentUser {
            let topicRef = db.collection("Users").document(user.uid).collection("topics").document(community.documentID)
            
            var data: [String: Any] = ["createDate": Timestamp(date: Date())]
            
            if community.language == .english {
                data["language"] = "en"
            }
            topicRef.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Succesfully subscribed to topic")
                    
                    if let _ = self.community {
                        // followTopic is called from other instances, where there ist no view instantiated, just the class
                        self.followButton.setTitle("Unfollow", for: .normal)
                    }
                    community.beingFollowed = true
                    self.updateFollowCount(fact: community, follow: true)
                }
            }
        }
    }
    
    func unfollowTopic(community: Community) {
        if let user = Auth.auth().currentUser {
            let topicRef = db.collection("Users").document(user.uid).collection("topics").document(community.documentID)
            
            topicRef.delete { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    community.beingFollowed = false
                    print("Successfully unfollowed")
                    
                    if let _ = self.community {
                        // followTopic is called from other instances, where there ist no view instantiated, just the class
                        self.followButton.setTitle("Follow", for: .normal)
                    }
                    self.updateFollowCount(fact: community, follow: false)
                }
            }
        }
    }
    
    func updateFollowCount(fact: Community, follow: Bool) {
        followButton.isEnabled = true   // updateFollowCount is called from other instances, where there ist no view instantiated, just the class
        
        if let user = Auth.auth().currentUser {
            
            var collectionRef: CollectionReference!
            if fact.language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(fact.documentID)
            
            if follow {
                ref.updateData([
                    "follower" : FieldValue.arrayUnion([user.uid])
                ])
            } else { //unfollowed
                ref.updateData([
                    "follower": FieldValue.arrayRemove([user.uid])
                ])
            }
        }
    }
}

extension CommunityHeaderView: BaseSegmentControlDelegate {
    func segmentChanged(to index: Int, direction: UIPageViewController.NavigationDirection) {
        delegate?.segmentedControlTapped(index: index, direction: direction)
    }
}
