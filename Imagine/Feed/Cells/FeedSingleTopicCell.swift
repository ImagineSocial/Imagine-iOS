//
//  FeedSingleTopicCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class FeedSingleTopicCell: BaseFeedCell {
    
    static var identifier = "FeedSingleTopicCell"
    
    //MARK:- IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    //MARK:- Variables
    private let singleTopicCellIdentifier = "SingleCommunityCollectionViewCell"
    
    private var addOnInfo: AddOn?
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "AddOnSingleCommunityCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: singleTopicCellIdentifier)
        
        self.initiateCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetValues()
    }
    
    //MARK:- Set Cell
    override func setCell() {
        super.setCell()
        
        if let post = post {
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell(post: post)
                }
            } else {
                setDefaultButtonImages()
            }
           
            
            if post.user == nil {
                if post.anonym {
                    self.setUser()
                } else {
                    self.checkForUser()
                }
            } else {
                setUser()
            }
            
            if let community = post.community {
                if community.title != "" {
                    self.loadSingleTopic(post: post, community: community)
                } else {
                    let communityRequest = CommunityRequest()
                    communityRequest.getCommunity(language: post.language, community: community, beingFollowed: false) { (community) in
                        self.loadSingleTopic(post: post, community: community)
                    }
                }
            }
            
            titleLabel.text = post.title
            feedLikeView.setPost(post: post)
            
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    //MARK:- Load Single Topic
    func loadSingleTopic(post: Post, community: Community) {
        let info = AddOn(style: .singleTopic, OP: "", documentID: "", fact: Community(), headerTitle: post.title, description: post.description ?? "", singleTopic: community)
        
        self.addOnInfo = info
        post.community = community

        self.collectionView.reloadData()
        self.layoutSubviews()
    }
}

//MARK:- UICollectionView
extension FeedSingleTopicCell: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let _ = addOnInfo {
            return 1
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: singleTopicCellIdentifier, for: indexPath) as? AddOnSingleCommunityCollectionViewCell {
            
            cell.contentView.clipsToBounds = true
            cell.halfTransparentBackgroundView.isHidden = true
            cell.isAddOnCell = false
            if let addOnInfo = addOnInfo {
                cell.info = addOnInfo
            }
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.contentSize.width, height: 400)
    }
    
}
