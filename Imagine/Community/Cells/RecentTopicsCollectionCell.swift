//
//  RecentTopicsCollectionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

protocol RecentTopicCellDelegate {
    func topicTapped(fact: Community)
}

class RecentTopicsCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var communities = [Community]()
    let placeHolderIdentifier = "PlaceHolderCell"
    
    let db = FirestoreRequest.shared.db
    
    var delegate: RecentTopicCellDelegate?
    
    override func awakeFromNib() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.delaysContentTouches = false
        
        collectionView.register(SmallTopicCell.self, forCellWithReuseIdentifier: SmallTopicCell.identifier)
        collectionView.register(UINib(nibName: "PlaceHolderCell", bundle: nil), forCellWithReuseIdentifier: placeHolderIdentifier)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        getFacts(initialFetch: true)
    }
    
    func getFacts(initialFetch: Bool) {
        
        let defaults = UserDefaults.standard
        let language = LanguageSelection.language
        var key: String!
        
        switch language {
        case .en:
            key = "recentTopics-en"
        case .de:
            key = "recentTopics"
        }
        let factStrings = defaults.stringArray(forKey: key) ?? [String]()
        
        if initialFetch {
            for string in factStrings {
                loadCommunity(with: string, language: language)
            }
        } else {
            if self.communities.count >= 10 {
                self.communities.removeLast()
            }
            
            self.communities = self.communities.filter { $0.id != factStrings[0] }
            
            loadCommunity(with: factStrings[0], language: language)
        }
    }
    
    func loadCommunity(with id: String, language: Language) {
        
        CommunityHelper.getCommunity(withID: id, language: language) { community in
            guard let community = community else {
                return
            }

            self.communities.insert(community, at: 0)
            self.collectionView.reloadData()
        }
    }
}

extension RecentTopicsCollectionCell: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        communities.count != 0 ? communities.count : 6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if communities.count != 0 {
            let community = communities[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SmallTopicCell.identifier, for: indexPath) as? SmallTopicCell {
                
                cell.community = community
                
                return cell
            }
        } else {
            // Blank Cell
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: placeHolderIdentifier, for: indexPath) as? PlaceHolderCell {
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if communities.count != 0 {
            let community = communities[indexPath.item]
            
            delegate?.topicTapped(fact: community)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(width: (collectionView.frame.size.height), height: (collectionView.frame.size.height))
    }
}
