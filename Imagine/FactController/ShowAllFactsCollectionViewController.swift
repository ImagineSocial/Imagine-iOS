//
//  ShowAllFactsCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class ShowAllFactsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RecentTopicDelegate {
    
    
    let factCellIdentifier = "FactCell"
    let discussionCellIdentifier = "DiscussionCell"
    let topicHeaderIdentifier = "TopicCollectionHeader"
    
    let collectionViewSpacing:CGFloat = 30
    
    let db = Firestore.firestore()
    let dataHelper = DataHelper()
    
    var topicFacts: [Fact]?
    var discussionFacts: [Fact]?
    
    var type: DisplayOption?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = .systemBackground
        } else {
            collectionView.backgroundColor = .white
        }

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
        
        let ref = db.collection("Facts").whereField("displayOption", isEqualTo: sortByString)
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    var facts = [Fact]()
                    for document in snap.documents {
                        let data = document.data()
                        
                        if let fact = self.dataHelper.addFact(documentID: document.documentID, data: data) {
                            facts.append(fact)
                        }
                    }
                    self.getCheckedTopics(type: type, topics: facts)
                }
            }
        }
    }
    
    func getCheckedTopics(type: DisplayOption, topics: [Fact]) {
        
        if let user = Auth.auth().currentUser {
            self.dataHelper.markFollowedTopics(userUID: user.uid, factList: topics) { (facts) in
                self.showTopics(type: type, topics: facts)
            }
        } else {
            showTopics(type: type, topics: topics)
        }
    }
    
    func showTopics(type: DisplayOption, topics: [Fact]) {
        switch type {
        case .fact:
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
            if let pageVC = segue.destination as? ArgumentPageViewController {
                if let chosenFact = sender as? Fact {
                    pageVC.fact = chosenFact
                    pageVC.recentTopicDelegate = self
                }
            }
        }
    }
    
    func topicSelected(fact: Fact) {
        let factVC = FactCollectionViewController()
        factVC.registerRecentFact(fact: fact)
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
            let fact = topics[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: factCellIdentifier, for: indexPath) as? FactCell {
                cell.fact = fact
                
                return cell
            }
        } else if let discussions = discussionFacts {
            let fact = discussions[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: discussionCellIdentifier, for: indexPath) as? DiscussionCell {
                
                cell.fact = fact
                
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
            let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-(collectionViewSpacing/2))
            
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
                    view.headerLabel.text = "Communities"
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
