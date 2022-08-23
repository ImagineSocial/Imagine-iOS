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
    
    var communityIsFollowed = false
    
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
        
        community.getFollowStatus { isFollowed in
            self.setFollowButton(isFollowed: isFollowed)
        }
        
        if let imageURL = community.imageURL, let url = URL(string: imageURL) {
            imageView.sd_setImage(with: url, completed: nil)
        }
        
        descriptionLabel.text = community.description
        titleLabel.text = community.title
        
        self.followerCountLabel.text = "Follower: \(community.followerCount ?? 0)"
        self.postCountLabel.text = "Posts: \(community.postCount ?? 0)"
    }
    
    @objc func followButtonTapped() {
        
        guard AuthenticationManager.shared.isLoggedIn else {
            delegate?.notLoggedIn()
            return
        }
        
        self.followButton.isEnabled = false
        communityIsFollowed ? unfollowTopic() : followTopic()
    }
    
    @objc func newPostButtonTapped() {
        delegate?.newPostTapped()
    }
    
    private func followTopic() {
        guard let community = community else {
            return
        }

        community.followTopic { success in
            if success {
                self.setFollowButton(isFollowed: true)
            }
        }
    }
    
    private func unfollowTopic() {
        guard let community = community else {
            return
        }

        community.unfollowTopic { success in
            if success {
                self.setFollowButton(isFollowed: false)
            }
        }
    }
    
    private func setFollowButton(isFollowed: Bool) {
        communityIsFollowed = isFollowed
        followButton.setTitle(isFollowed ? "Unfollow" : "Follow", for: .normal)
        followButton.isEnabled = true
    }
}

extension CommunityHeaderView: BaseSegmentControlDelegate {
    func segmentChanged(to index: Int, direction: UIPageViewController.NavigationDirection) {
        delegate?.segmentedControlTapped(index: index, direction: direction)
    }
}
