//
//  SingleTopicAddOnCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 03.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class SingleTopicAddOnCell: UITableViewCell {
    
    @IBOutlet weak var topicImageView: UIImageView!
    @IBOutlet weak var topicTitleLabel: UILabel!
    @IBOutlet weak var topicDescriptionLabel: UILabel!
    @IBOutlet weak var topicPreviewCollectionView: UICollectionView!
    @IBOutlet weak var topicPostCountLabel: UILabel!
    @IBOutlet weak var topicFollowerLabel: UILabel!
    @IBOutlet weak var gradientView: DesignablePopUp!
    @IBOutlet weak var topicPreviewCollectionViewHeightConstraint: NSLayoutConstraint!
    
    let previewCellIdentifier = "SmallTopicCell"
    let db = Firestore.firestore()
    let postHelper = PostHelper()
    
    var isFetchingPreviewPosts = false
    
    var previewPosts: [Post]?
    
    var info: OptionalInformation? {
        didSet {
            if let info = info {
                let fact = info.fact
                
                if !isFetchingPreviewPosts {
                    self.isFetchingPreviewPosts = true
                    self.getPreviewPictures(documentID: fact.documentID)
                    
                }
                self.topicTitleLabel.text = fact.title
                self.topicDescriptionLabel.text = fact.description
                if let url = URL(string: fact.imageURL) {
                    topicImageView.sd_setImage(with: url, completed: nil)
                }
                
                fact.getPostCount { (count) in
                    self.topicPostCountLabel.text = "Beiträge: \(count)"
                }
                fact.getFollowerCount { (count) in
                    self.topicFollowerLabel.text = "Follower: \(count)"
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
                                self.setGradientView()
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
        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 2
        if #available(iOS 13.0, *) {
            contentView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            contentView.layer.borderColor = UIColor.ios12secondarySystemBackground.cgColor
        }
    
        contentView.clipsToBounds = true
        backgroundColor =  .clear
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the values for top,left,bottom,right margins
        let margins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        contentView.frame = contentView.frame.inset(by: margins)
    }
    
    override func prepareForReuse() {
        topicPreviewCollectionViewHeightConstraint.constant = 125
    }
    
    func setGradientView() {
        //Gradient
        DispatchQueue.global(qos: .default).async {
            
            let gradient = CAGradientLayer()
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 0.6)
            let whiteColor = UIColor.white
            gradient.colors = [whiteColor.withAlphaComponent(0.0).cgColor, whiteColor.withAlphaComponent(0.5).cgColor, whiteColor.withAlphaComponent(0.7).cgColor]
            gradient.locations = [0.0, 0.5, 1]
            gradient.frame = self.gradientView.bounds
            
            DispatchQueue.main.async {
                
                self.gradientView.layer.mask = gradient
            }
        }
    }
}

extension SingleTopicAddOnCell: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let posts = self.previewPosts else { return 0}
        
        return posts.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let posts = previewPosts {
            let post = posts[indexPath.item]
            
            if let cell = topicPreviewCollectionView.dequeueReusableCell(withReuseIdentifier: previewCellIdentifier, for: indexPath) as? SmallTopicCell {
                
//                cell.cellNameLabel.font = UIFont(name: "IBMPlexSans", size: 12)
//                cell.cellNameLabel.minimumScaleFactor = 0.75
//                cell.cellNameLabel.numberOfLines = 0
//                cell.cellNameLabel.text = post.title
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
