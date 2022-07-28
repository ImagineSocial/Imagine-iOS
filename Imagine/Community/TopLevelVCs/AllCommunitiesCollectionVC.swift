//
//  ShowAllFactsCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class AllCommunitiesCollectionVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, RecentTopicDelegate {
    
    
    let factCellIdentifier = "FactCell"
    let discussionCellIdentifier = "DiscussionCell"
    let topicHeaderIdentifier = "TopicCollectionHeader"
    
    let collectionViewSpacing: CGFloat = 24
    
    let db = FirestoreRequest.shared.db
    let dataHelper = DataRequest()
    
    var topicFacts: [Community]?
    var discussionFacts: [Community]?
    
    var type: DisplayOption?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .systemBackground
        collectionView.register(UINib(nibName: "FactCell", bundle: nil), forCellWithReuseIdentifier: factCellIdentifier)
        collectionView.register(UINib(nibName: "DiscussionCell", bundle: nil), forCellWithReuseIdentifier: discussionCellIdentifier)
        collectionView.register(UINib(nibName: "TopicCollectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: topicHeaderIdentifier)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
        }
        
        
        if let type = type {
            getTopics(type: type)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
 
    
    func getTopics(type: DisplayOption) {
        let sortByString = getDisplayOptionString(type: type)
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection.language
        if language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.whereField("displayOption", isEqualTo: sortByString)
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    var facts = [Community]()
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let fact = CommunityHelper.shared.getCommunity(documentID: document.documentID, data: data) {
                            facts.append(fact)
                        }
                    }
                    self.showTopics(type: type, topics: facts)
                }
            }
        }
    }
    
    func showTopics(type: DisplayOption, topics: [Community]) {
        switch type {
        case .discussion:
            self.discussionFacts = topics
        case .topic:
            self.topicFacts = topics
        }
        self.collectionView.reloadData()
    }
    
    func getDisplayOptionString(type: DisplayOption) -> String {
        switch type {
        case .topic:
            return "topic"
        default:
            return "fact"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPageVC" {
            if let pageVC = segue.destination as? CommunityPageVC {
                if let chosenCommunity = sender as? Community {
                    pageVC.community = chosenCommunity
                    pageVC.recentTopicDelegate = self
                }
            }
        }
    }
    
    func topicSelected(community: Community) {
        let communityVC = CommunityCollectionVC()
        communityVC.registerRecentFact(community: community)
    }
    
    // MARK: -UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let facts = topicFacts {
            return facts.count
        } else if let discussions = discussionFacts {
            return discussions.count
        } else {
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let topics = topicFacts {
            let community = topics[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: factCellIdentifier, for: indexPath) as? FactCell {
                cell.community = community
                
                return cell
            }
        } else if let discussions = discussionFacts {
            let community = discussions[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: discussionCellIdentifier, for: indexPath) as? DiscussionCell {
                
                cell.community = community
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let _ = topicFacts {
            let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-collectionViewSpacing)
            
            
            return newSize
            
        } else if let _ = discussionFacts {
            let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: collectionView.frame.size.width/2)
            
            return newSize
        } else {
            let newSize = CGSize(width: (collectionView.frame.size.width/3)-collectionViewSpacing, height: (collectionView.frame.size.width/4)-collectionViewSpacing)
            
            return newSize
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let topics = topicFacts {

            let fact = topics[indexPath.item]

            performSegue(withIdentifier: "toPageVC", sender: fact)

        } else if let discussions = discussionFacts {

            let fact = discussions[indexPath.item]
            performSegue(withIdentifier: "toPageVC", sender: fact)


        }
    }
    
    //MARK: CollectionViewHeader

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: topicHeaderIdentifier, for: indexPath) as? TopicCollectionHeader {
            
            view.headerLabel.font = UIFont(name: "IBMPlexSans-Bold", size: 28)
            
            if let type = type {
                if type == .topic {
                    view.headerLabel.text = NSLocalizedString("communities", comment: "communities")
                } else {
                    view.headerLabel.text = NSLocalizedString("discussions", comment: "discussions")
                }
            }
            
            return view
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: collectionView.frame.width, height: 70)
        
    }
}
