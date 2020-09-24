//
//  CommunityHeaderView.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol CommunityFeedHeaderDelegate {
    func segmentedControlTapped(index: Int, direction: UIPageViewController.NavigationDirection)
    func newPostTapped()
}

class CommunityHeaderView: UIView {
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescriptionLabeel: UILabel!
    @IBOutlet weak var newPostButton: UILabel!
    @IBOutlet weak var headerSegmentedControl: UISegmentedControl!
    @IBOutlet weak var followButton: DesignableButton!
    @IBOutlet weak var followerCountLabel: UILabel!
    @IBOutlet weak var postCountLabel: UILabel!
    
    var segmentIndicatorCenterXConstraint: NSLayoutConstraint?
    var segmentIndicatorWidthConstraint: NSLayoutConstraint?
    
    var delegate: CommunityFeedHeaderDelegate?
    var lastIndex = 0
    
    let db = Firestore.firestore()
    
    var community: Fact? {
            didSet {
                if let community = community {
                    
                    if let url = URL(string: community.imageURL) {
                        headerImageView.sd_setImage(with: url, completed: nil)
                    }
                    
                    if community.beingFollowed {
                        followButton.setTitle("Unfollow", for: .normal)
                    }
                    
                    headerDescriptionLabeel.text = community.description
                    headerTitleLabel.text = community.title
                    
                    self.followerCountLabel.text = String(community.followerCount)
                    self.postCountLabel.text = String(community.postCount)
                } else {
                    print("No Info we got")
                }
            }
        }
    
    override func awakeFromNib() {
        
        setSegmentedIndicatorView()
    }
    
    func setSegmentedIndicatorView() {
        let bg = UIImage()
        headerSegmentedControl.setBackgroundImage(bg, for: .normal, barMetrics: .default)
        headerSegmentedControl.setDividerImage(bg, forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        
        if #available(iOS 13.0, *) {
            headerSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "IBMPlexSans-Medium", size: 15)!, NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel], for: .normal)
            headerSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "IBMPlexSans-Medium", size: 16)!, NSAttributedString.Key.foregroundColor: UIColor.label], for: .selected)
        } else {
            headerSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "IBMPlexSans-Medium", size: 15)!, NSAttributedString.Key.foregroundColor: UIColor.lightGray], for: .normal)
            headerSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "IBMPlexSans-Medium", size: 16)!, NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        }
        
        self.addSubview(segmentIndicator)
        segmentIndicator.bottomAnchor.constraint(equalTo: self.headerSegmentedControl.bottomAnchor, constant: 3).isActive = true
        segmentIndicator.heightAnchor.constraint(equalToConstant: 2).isActive = true
        let width: CGFloat = CGFloat(15+headerSegmentedControl.titleForSegment(at: 0)!.count*8)
        
        self.segmentIndicatorWidthConstraint =  segmentIndicator.widthAnchor.constraint(equalToConstant: width)
        self.segmentIndicatorWidthConstraint!.isActive = true
        self.segmentIndicatorCenterXConstraint = segmentIndicator.centerXAnchor.constraint(equalToSystemSpacingAfter: headerSegmentedControl.centerXAnchor, multiplier: CGFloat(1/headerSegmentedControl.numberOfSegments))
        self.segmentIndicatorCenterXConstraint!.isActive = true
        
    }

    @IBAction func segmentedControlChanged(_ sender: Any) {
        
        let index = headerSegmentedControl.selectedSegmentIndex
        
        if index > lastIndex {
            delegate?.segmentedControlTapped(index: index, direction: .forward)
        } else {
            delegate?.segmentedControlTapped(index: index, direction: .reverse)
        }
        
        let numberOfSegments = CGFloat(headerSegmentedControl.numberOfSegments)
        let selectedIndex = CGFloat(index)
        let titlecount = CGFloat((headerSegmentedControl.titleForSegment(at: Int(selectedIndex))!.count))
        let newX = CGFloat(1/(numberOfSegments / CGFloat(3.0 + CGFloat(selectedIndex-1.0)*2.0)))
        let newWidth = CGFloat(15+titlecount*8)
        
        self.segmentIndicatorWidthConstraint!.constant = newWidth
        self.segmentIndicatorCenterXConstraint = self.segmentIndicatorCenterXConstraint!.setMultiplier(multiplier: newX)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.layoutIfNeeded()
        }) { (_) in
            self.lastIndex = index
        }
    }
    
    @IBAction func followTopicButtonTapped(_ sender: Any) {
        guard let community = community else { return }
        
        self.followButton.isEnabled = false
        if community.beingFollowed {
            unfollowTopic()
        } else {
            followTopic()
        }
    }
    
    @IBAction func newPostButtonTapped(_ sender: Any) {
        delegate?.newPostTapped()
    }
    
    func followTopic() {
        if let community = community {
            if let user = Auth.auth().currentUser {
                let topicRef = db.collection("Users").document(user.uid).collection("topics").document(community.documentID)
                
                topicRef.setData(["createDate": Timestamp(date: Date())]) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        print("Succesfully subscribed to topic")
                        self.followButton.setTitle("Unfollow", for: .normal)
                        community.beingFollowed = true
                        self.updateFollowCount(fact: community, follow: true)
                    }
                }
            }
        }
    }
    
    func unfollowTopic() {
        if let community = community {
            if let user = Auth.auth().currentUser {
                let topicRef = db.collection("Users").document(user.uid).collection("topics").document(community.documentID)
                
                topicRef.delete { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        community.beingFollowed = false
                        print("Successfully unfollowed")
                        self.followButton.setTitle("Follow", for: .normal)
                        self.updateFollowCount(fact: community, follow: false)
                    }
                }
            }
        }
    }
    
    func updateFollowCount(fact: Fact, follow: Bool) {
        self.followButton.isEnabled = true
        if let user = Auth.auth().currentUser {
            
            let ref = db.collection("Facts").document(fact.documentID)
            
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
    
    
    let segmentIndicator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            v.backgroundColor = UIColor.label
        } else {
            v.backgroundColor = UIColor.black
        }
        return v
    }()
    
    class func loadViewFromNib(named: String? = nil) -> Self {
        let name = named ?? "\(Self.self)"
        guard
            let nib = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
            else { fatalError("missing expected nib named: \(name)") }
        guard
            /// we're using `first` here because compact map chokes compiler on
            /// optimized release, so you can't use two views in one nib if you wanted to
            /// and are now looking at this
            let view = nib.first as? Self
            else { fatalError("view of type \(Self.self) not found in \(nib)") }
        return view
    }
    
}
