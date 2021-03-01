//
//  FeedSingleTopicCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.09.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class FeedSingleTopicCell: BaseFeedCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let singleTopicCellIdentifier = "SingleCommunityCollectionViewCell"
    var delegate: PostCellDelegate?
    
    var post:Post? {
        didSet {
            setCell()
        }
    }
    
    var addOnInfo: AddOn?
    
    override func awakeFromNib() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "AddOnSingleCommunityCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: singleTopicCellIdentifier)
        
        self.initiateCell(thanksButton: thanksButton, wowButton: wowButton, haButton: haButton, niceButton: niceButton, factImageView: factImageView, profilePictureImageView: profilePictureImageView)
    }
    
    func setCell() {
        if let post = post {
            
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                thanksButton.setTitle(String(post.votes.thanks), for: .normal)
                wowButton.setTitle(String(post.votes.wow), for: .normal)
                haButton.setTitle(String(post.votes.ha), for: .normal)
                niceButton.setTitle(String(post.votes.nice), for: .normal)
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell()
                }
                
            } else {
                thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
                wowButton.setImage(UIImage(named: "wowButton"), for: .normal)
                haButton.setImage(UIImage(named: "haButton"), for: .normal)
                niceButton.setImage(UIImage(named: "niceButton"), for: .normal)
            }
           
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getName()
                }
            } else {
                setUser()
            }
            
            if let fact = post.fact {
                if fact.title != "" {
                    self.loadSingleTopic(post: post, community: fact)
                } else {
                    self.loadFact(language: post.language, fact: fact, beingFollowed: false) { (fact) in
                        self.loadSingleTopic(post: post, community: fact)
                    }
                }
            }
            
            titleLabel.text = post.title
            descriptionPreviewLabel.text = post.description
            createDateLabel.text = post.createTime
            commentCountLabel.text = String(post.commentCount)
            
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    func loadSingleTopic(post: Post, community: Community) {
        let info = AddOn(style: .singleTopic, OP: "", documentID: "", fact: Community(), headerTitle: post.title, description: post.description, singleTopic: community)
        
        self.addOnInfo = info
        post.fact = community
        print("##LoadedSingleTopic")
        self.collectionView.reloadData()
        self.layoutSubviews()
    }
    
    func setUser() {
        if let post = post {
            
            if post.anonym {
                if let anonymousName = post.anonymousName {
                    OPNameLabel.text = anonymousName
                } else {
                    OPNameLabel.text = Constants.strings.anonymPosterName
                }
                profilePictureImageView.image = UIImage(named: "anonym-user")
            } else {
                OPNameLabel.text = post.user.displayName
                
                // Profile Picture
                if let url = URL(string: post.user.imageURL) {
                    profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                } else {
                    profilePictureImageView.image = UIImage(named: "default-user")
                }
            }
        }
    }
    
    
    var index = 0
    func getName() {
        if index < 20 {
            if let post = self.post {
                if post.user.displayName == "" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.getName()
                        self.index+=1
                    }
                } else {
                    setUser()
                }
            }
        }
    }
    
    //MARK:-Buttons
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            thanksButton.isEnabled = false
            delegate?.thanksTapped(post: post)
            post.votes.thanks = post.votes.thanks+1
            showButtonText(post: post, button: thanksButton)
        }
    }
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            wowButton.isEnabled = false
            delegate?.wowTapped(post: post)
            post.votes.wow = post.votes.wow+1
            showButtonText(post: post, button: wowButton)
        }
    }
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            haButton.isEnabled = false
            delegate?.haTapped(post: post)
            post.votes.ha = post.votes.ha+1
            showButtonText(post: post, button: haButton)
        }
    }
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            niceButton.isEnabled = false
            delegate?.niceTapped(post: post)
            post.votes.nice = post.votes.nice+1
            self.showButtonText(post: post, button: self.niceButton)
        }
    }
    
    @IBAction func reportPressed(_ sender: Any) {
        if let post = post {
            delegate?.reportTapped(post: post)
        }
    }
    
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let post = post {
            if !post.anonym {
                delegate?.userTapped(post: post)
            }
        }
    }
    
    @IBAction func linkedFactTapped(_ sender: Any) {
        if let fact = post?.fact {
            delegate?.factTapped(fact: fact)
        }
    }
}

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
