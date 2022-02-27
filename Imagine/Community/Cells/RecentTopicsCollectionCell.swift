//
//  RecentTopicsCollectionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

protocol RecentTopicCellDelegate {
    func topicTapped(fact: Community)
}

class RecentTopicsCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var communities = [Community]()
    let identifier = "SmallTopicCell"
    let placeHolderIdentifier = "PlaceHolderCell"
    
    let db = FirestoreRequest.shared.db
    
    var delegate: RecentTopicCellDelegate?
    
    override func awakeFromNib() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.delaysContentTouches = false
        
        collectionView.register(UINib(nibName: "SmallTopicCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        collectionView.register(UINib(nibName: "PlaceHolderCell", bundle: nil), forCellWithReuseIdentifier: placeHolderIdentifier)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        getFacts(initialFetch: true)
    }
    
    func getFacts(initialFetch: Bool) {
        
        let defaults = UserDefaults.standard
        let language = LanguageSelection().getLanguage()
        var key: String!
        
        switch language {
        case .english:
            key = "recentTopics-en"
        case .german:
            key = "recentTopics"
        }
        let factStrings = defaults.stringArray(forKey: key) ?? [String]()
        let user = Auth.auth().currentUser
        
        if initialFetch {
            for string in factStrings {
                loadFact(user: user, factID: string, language: language)
            }
        } else {
            if self.communities.count >= 10 {
                self.communities.removeLast()
            }
            
            self.communities = self.communities.filter{ $0.documentID != factStrings[0] }
            
            loadFact(user: user, factID: factStrings[0], language: language)
        }
    }
    
    func loadFact(user: Firebase.User?, factID: String, language: Language) {
        var collectionRef: CollectionReference!
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let factRef = collectionRef.document(factID)
        
        factRef.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snapshot = snap, let data = snapshot.data(), let community = CommunityHelper.shared.getCommunity(currentUser: user, documentID: snapshot.documentID, data: data) {
                    self.communities.insert(community, at: 0)
                    self.collectionView.reloadData()
                }
            }
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
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? SmallTopicCell {
                
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
            let fact = communities[indexPath.item]
            
            fact.getFollowStatus { (isFollowed) in
                if isFollowed {
                    fact.beingFollowed = true
                    self.delegate?.topicTapped(fact: fact)
                } else {
                    self.delegate?.topicTapped(fact: fact)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let newSize = CGSize(width: (collectionView.frame.size.height), height: (collectionView.frame.size.height))
        
        return newSize
    }
}


class SmallTopicCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
        }
    }
    
    func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ?
            CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) :
            CGAffineTransform.identity
        })
    }
    
    override func awakeFromNib() {
        cellImageView.contentMode = .scaleAspectFill
        
        clipsToBounds = false
        layer.masksToBounds = true
    }
    
    override func prepareForReuse() {
        cellImageView.image = nil
    }
    
    var community: Community? {
        didSet {
            guard let community = community else { return }
            
            if let url = URL(string: community.imageURL) {
                cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-community"), options: [], completed: nil)
            } else {
                cellImageView.image = UIImage(named: "default-community")
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cellImageView.layer.cornerRadius = cellImageView.frame.width / 2
    }
}
