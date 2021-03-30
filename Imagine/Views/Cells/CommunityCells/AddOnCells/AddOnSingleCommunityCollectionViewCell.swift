//
//  AddOnSingleCommunityCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class AddOnSingleCommunityCollectionViewCell: BaseAddOnCollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var topicImageView: UIImageView!
    @IBOutlet weak var topicTitleLabel: UILabel!
    @IBOutlet weak var topicDescriptionLabel: UILabel!
    @IBOutlet weak var topicPreviewCollectionView: UICollectionView!
    @IBOutlet weak var topicPostCountLabel: UILabel!
    @IBOutlet weak var topicFollowerLabel: UILabel!
    @IBOutlet weak var topicPreviewCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addOnTitleLabel: UILabel!
    @IBOutlet weak var addOnDescriptionLabel: UILabel!
    @IBOutlet weak var halfTransparentBackgroundView: UIView!
    
    let previewCellIdentifier = "SmallTopicCell"
    let postHelper = FirestoreRequest()
    
    var isFetchingPreviewPosts = false
        
    var previewPosts: [Post]?
    
    var info: AddOn? {
        didSet {
            if let info = info {
                
                if let title = info.headerTitle {
                    addOnTitleLabel.text = title
                }
                addOnDescriptionLabel.text = info.description
                
                if let community = info.singleTopic {
                    print("URL: \(community.imageURL), \(community.title), \(community.documentID)")
                    if !isFetchingPreviewPosts {
                        self.isFetchingPreviewPosts = true
                        self.getPreviewPictures(community: community)
                    }
                    self.topicTitleLabel.text = community.title
                    self.topicDescriptionLabel.text = community.description
                    if let url = URL(string: community.imageURL) {
                        topicImageView.sd_setImage(with: url, completed: nil)
                    }
                    
                    self.topicPostCountLabel.text = "Posts: \(community.postCount)"
                    self.topicFollowerLabel.text = "Follower: \(community.followerCount)"
                }
            }
        }
    }
    
    func getPreviewPictures(community: Community) {
        if community.documentID != "" {
            if self.previewPosts == nil {
                self.postHelper.getPreviewPicturesForCommunity(community: community) { [weak self] (posts) in
                    DispatchQueue.main.async {
                        if let posts = posts, posts.count != 0, let self = self {
                            print("Got posts for SingleAddOn: \(posts)")
                            self.previewPosts = posts
                            self.topicPreviewCollectionView.reloadData()
                            self.isFetchingPreviewPosts = false
                        }
                    }
                }
            }
        }
    }
    
    override func awakeFromNib() {
        //CollectionView
        topicPreviewCollectionView.register(UINib(nibName: "SmallTopicCell", bundle: nil), forCellWithReuseIdentifier: previewCellIdentifier)
        
        if let layout = topicPreviewCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
        }
        
        topicPreviewCollectionView.delegate = self
        topicPreviewCollectionView.dataSource = self
        
        //Cell UI
        halfTransparentBackgroundView.layer.cornerRadius = 8
        
        topicPreviewCollectionView.layer.cornerRadius = 8
        contentView.layer.cornerRadius = cornerRadius
        containerView.layer.cornerRadius = cornerRadius
    }
    
    override func prepareForReuse() {
        topicPreviewCollectionViewHeightConstraint.constant = 125
    }
    
}

extension AddOnSingleCommunityCollectionViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let posts = self.previewPosts else { return 0}
        
        return posts.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let posts = previewPosts {
            let post = posts[indexPath.item]
            
            if let cell = topicPreviewCollectionView.dequeueReusableCell(withReuseIdentifier: previewCellIdentifier, for: indexPath) as? SmallTopicCell {
                
                cell.cellNameLabel.isHidden = true
                cell.gradientView.isHidden = true
                
                if let url = URL(string: post.imageURL) {
                    cell.cellImageView.sd_setImage(with: url, completed: nil)
                    
                } else {
                    // Get the link image oder whatever
                }
                //                cell.setGradientView()
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = topicPreviewCollectionView.frame.width
        let height = topicPreviewCollectionView.frame.height
        let spacing: CGFloat = 22   //FML
        
        let cellConstant = (width-spacing)/3
        
        return CGSize(width: cellConstant, height: height)
    }
    
}
