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
    let db = Firestore.firestore()
    let postHelper = PostHelper()
    
    var isFetchingPreviewPosts = false
        
    var previewPosts: [Post]?
    
    var info: OptionalInformation? {
        didSet {
            if let info = info {
                if let fact = info.singleTopic {
                    
                    if !isFetchingPreviewPosts {
                        self.isFetchingPreviewPosts = true
                        self.getPreviewPictures(documentID: fact.documentID)
                    }
                    self.topicTitleLabel.text = fact.title
                    self.topicDescriptionLabel.text = fact.description
                    if let url = URL(string: fact.imageURL) {
                        topicImageView.sd_setImage(with: url, completed: nil)
                    }
                    
                    if let title = info.headerTitle {
                        addOnTitleLabel.text = title
                    }
                    addOnDescriptionLabel.text = info.description
                    
                    fact.getPostCount { (count) in
                        self.topicPostCountLabel.text = "Beiträge: \(count)"
                    }
                    fact.getFollowerCount { (count) in
                        self.topicFollowerLabel.text = "Follower: \(count)"
                    }
                }
            }
        }
    }
    
    func getPreviewPictures(documentID: String) {
        if documentID != "" {
            if self.previewPosts == nil {
                DispatchQueue.global(qos: .default).async {
                    self.postHelper.getPostsForFact(factID: documentID, forPreviewPictures: true) { (posts) in
                        DispatchQueue.main.async {
                            if posts.count != 0 {
                                print("Got the singleTopicPosts")
                                self.previewPosts = posts
                                self.topicPreviewCollectionView.reloadData()
                                self.isFetchingPreviewPosts = false
                            } else {
                                self.topicPreviewCollectionViewHeightConstraint.constant = 0
                                self.layoutIfNeeded()
                            }
                        }
                    }
                }
            }
        } else {    // AddOnStoreViewController
            
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
        if #available(iOS 13.0, *) {
            layer.shadowColor = UIColor.label.cgColor
        } else {
            layer.shadowColor = UIColor.black.cgColor
        }
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.6
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
