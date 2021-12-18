//
//  CommunityCollectionVC+CollectionView.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension CommunityCollectionVC {
    
    func setupCollectionView() {
        collectionView.register(UINib(nibName: "TopicCollectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: topicHeaderIdentifier)
        collectionView.register(UINib(nibName: "TopicCollectionFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: topicFooterIdentifier)
        collectionView.register(UINib(nibName: "FactCell", bundle: nil), forCellWithReuseIdentifier: FactCell.identifier)
        collectionView.register(UINib(nibName: "RecentTopicsCollectionCell", bundle: nil), forCellWithReuseIdentifier: recentTopicsCellIdentifier)
        collectionView.register(UINib(nibName: "DiscussionCell", bundle: nil), forCellWithReuseIdentifier: discussionCellIdentifier)
        collectionView.register(UINib(nibName: "FollowedTopicCell", bundle: nil), forCellWithReuseIdentifier: followedTopicCellIdentifier)
        collectionView.register(UINib(nibName: "PlaceHolderCell", bundle: nil), forCellWithReuseIdentifier: placeHolderIdentifier)
        
        collectionView.delaysContentTouches = false
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        4
    }
    
  


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        } else if section == 1 {
            if isLoading {
                return 8
            } else {
                if topicCommunities.count <= 8 {
                    return topicCommunities.count
                } else {
                    return 8
                }
            }
        } else if section == 2 {
            return discussionCommunities.count
        } else {
            return followedCommunities.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var community: Community?
        
        if indexPath.section == 0 { // First wide cell for recentTopics
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: recentTopicsCellIdentifier, for: indexPath) as? RecentTopicsCollectionCell {
                
                cell.delegate = self
                
                return cell
            }
        } else if  indexPath.section == 1 {    //Other cells
            if isLoading {
                // Blank Cell
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: placeHolderIdentifier, for: indexPath) as? PlaceHolderCell {
                    
                    return cell
                }
            } else {
                community = topicCommunities[indexPath.row]
            }
        } else if  indexPath.section == 2 {
            community = discussionCommunities[indexPath.row]
        } else {
            community = followedCommunities[indexPath.row]
        }
        
        if let fact = community {
            
            if indexPath.section == 1 {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FactCell.identifier, for: indexPath) as? FactCell {
                    
                    cell.fact = fact
                    
                    return cell
                }
            } else if indexPath.section == 2 {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: discussionCellIdentifier, for: indexPath) as? DiscussionCell {
                    
                    cell.fact = fact
                    
                    return cell
                }
            } else if indexPath.section == 3 {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: followedTopicCellIdentifier, for: indexPath) as? FollowedTopicCell {
                    
                    cell.fact = fact
                    
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        if indexPath.section == 0 { // Last Selected Communities
            let newSize = CGSize(width: (collectionView.frame.size.width)-(collectionViewSpacing+10), height: (collectionView.frame.size.width / 4.5))
            
            return newSize
        } else if indexPath.section == 1 {    // normal Communities
            
            let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-collectionViewSpacing)
            
            return newSize
            
        } else if indexPath.section == 2 { // Discussions
            
            let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: collectionView.frame.size.width/2)
            
            return newSize
            
        } else {    // Followed Communities
            let newSize = CGSize(width: (collectionView.frame.size.width), height: 40)
            
            return newSize
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var community: Community?
        
        if indexPath.section == 0 {
            
        } else if indexPath.section == 1 {
            community = topicCommunities[indexPath.row]
        } else if indexPath.section == 2 {
            community = discussionCommunities[indexPath.row]
        } else {
            community = followedCommunities[indexPath.row]
        }
        
        guard let community = community else {
            return
        }
        
        if let addFactToPost = addFactToPost{
            
            if addFactToPost == .newPost {
                self.setFactForPost(fact: community)
            } else {
                showAddItemAlert(for: community)
            }
        } else {
            performSegue(withIdentifier: "toPageVC", sender: community)
            self.topicSelected(fact: community)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {  // View above CollectionView
            if indexPath.section == 0 {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "factCollectionFirstHeader", for: indexPath) as? FirstCollectionHeader {
                    
                    if addFactToPost == .optInfo {
                        view.headerLabel.font = UIFont(name: "IBMPlexSans", size: 16)
                        view.headerLabel.numberOfLines = 0
                        view.headerLabel.text = NSLocalizedString("choose_topic_for_addOn_header", comment: "choose one")
                    }
                    return view
                }
            } else {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: topicHeaderIdentifier, for: indexPath) as? TopicCollectionHeader {
                    
                    switch indexPath.section {
                    case 1:
                        view.headerLabel.text = NSLocalizedString("popular", comment: "popular")
                    case 2:
                        view.headerLabel.text = NSLocalizedString("current_discussions", comment: "current discussions")
                    case 3:
                        view.headerLabel.text = NSLocalizedString("followed_communities", comment: "followed communities")
                    default:
                        break
                    }
                    
                    return view
                }
            }
        } else if kind == UICollectionView.elementKindSectionFooter {
            if indexPath.section != 0 && indexPath.section != 3 {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: topicFooterIdentifier, for: indexPath) as? TopicCollectionFooter {
                    
                    view.delegate = self
                    if indexPath.section == 1 {
                        view.type = .topic
                    } else if indexPath.section == 2 {
                        view.type = .discussion
                    }
                    
                    return view
                }
            }
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            return CGSize(width: collectionView.frame.width, height: 70)
        case 1:
            return CGSize(width: collectionView.frame.width, height: 35)
        default:
            return CGSize(width: collectionView.frame.width, height: 50)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        switch section {
        case 0, 3:
            return CGSize(width: collectionView.frame.width, height: 0)
        default:
            return CGSize(width: collectionView.frame.width, height: 85)
        }
    }
}
