//
//  FeedSingleTopicCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class FeedSingleTopicCell: BaseFeedCell {
    
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
    
    //MARK:- Set Cell
    override func setCell() {
        if let post = post {
            feedUserView.delegate = self
            
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
           
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getUser()
                }
            } else {
                setUser()
            }
            
            if let fact = post.fact {
                if fact.title != "" {
                    self.loadSingleTopic(post: post, community: fact)
                } else {
                    self.getCommunity(language: post.language, community: fact, beingFollowed: false) { (fact) in
                        self.loadSingleTopic(post: post, community: fact)
                    }
                }
            }
            
            titleLabel.text = post.title
            descriptionPreviewLabel.text = post.description
            commentCountLabel.text = String(post.commentCount)
            
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    //MARK:- Load Single Topic
    func loadSingleTopic(post: Post, community: Community) {
        let info = AddOn(style: .singleTopic, OP: "", documentID: "", fact: Community(), headerTitle: post.title, description: post.description, singleTopic: community)
        
        self.addOnInfo = info
        post.fact = community
        print("##LoadedSingleTopic")
        self.collectionView.reloadData()
        self.layoutSubviews()
    }
    
    
    //MARK:- IBActions
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: thanksButton)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: wowButton)
        }
    }
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: haButton)
        }
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            self.registerVote(post: post, button: self.niceButton)
        }
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
        print("##Return size SingleTopic: \(collectionView.contentSize)")

        return CGSize(width: collectionView.contentSize.width, height: 400)
    }
    
}
