//
//  FactCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAnalytics
import EasyTipView

protocol LinkFactWithPostDelegate {
    func selectedFact(fact: Community, isViewAlreadyLoaded: Bool)
}

protocol TopOfCollectionViewDelegate {
    func sortFactsTapped(option: FactCollectionDisplayOption)
}

enum FactCollectionDisplayOption {
    case all
    case justFacts
    case justTopics
}

enum AddFactToPostType {
    case optInfo
    case newPost
}

class CommunityCollectionVC: UICollectionViewController, UICollectionViewDelegateFlowLayout, RecentTopicDelegate {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var topicFacts = [Community]()
    var discussionFacts = [Community]()
    var followedFacts = [Community]()
    
//    var displayOption: FactCollectionDisplayOption = .all
    
    let db = Firestore.firestore()
    let dataHelper = DataRequest()
    
    var addFactToPost : AddFactToPostType?
    var delegate: LinkFactWithPostDelegate?
    weak var addItemDelegate: AddItemDelegate?
    
    var addOn: AddOn?
    
    var tipView: EasyTipView?
    
    let collectionViewSpacing:CGFloat = 24
    
    let recentTopicsCellIdentifier = "RecentTopicsCollectionCell"
    let discussionCellIdentifier = "DiscussionCell"
    let followedTopicCellIdentifier = "FollowedTopicCell"
    let placeHolderIdentifier = "PlaceHolderCell"
    
    let topicHeaderIdentifier = "TopicCollectionHeader"
    let topicFooterIdentifier = "TopicCollectionFooter"
        
    var reloadRecentTopics = false
    var isLoading = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFacts()
        
        if addFactToPost == .newPost {
            self.setDismissButton()
        }
        
        setupCollectionView()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.view.activityStartAnimating()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        //FML
        if let _ = addFactToPost {  // TO show the search bar when you want to select a topic
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        if reloadRecentTopics {
            if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? RecentTopicsCollectionCell {
                cell.getFacts(initialFetch: false)
                self.reloadRecentTopics = false
            }
            //else : The  scrollViewDidEndDecelerating Method will catch it if it is visible again
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        if let tipView = tipView {
            tipView.dismiss()
            self.tipView = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
            self.tipView = nil
        }
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }

   
    func getFacts() {
        dataHelper.getData(get: .communities) { (facts) in    // gets the first 8 topic communities by popularity

            if let facts = facts as? [Community] {
                self.topicFacts = facts
                self.collectionView.reloadData()    //The user thinks it is loaded
                
                var collectionRef: CollectionReference!
                let language = LanguageSelection().getLanguage()
                if language == .english {
                    collectionRef = self.db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = self.db.collection("Facts")
                }
                let ref = collectionRef.whereField("displayOption", isEqualTo: "fact").order(by: "popularity", descending: true).limit(to: 6)
                
                let user = Auth.auth().currentUser
                
                ref.getDocuments { (snap, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let snap = snap {
                            var discussionCount = snap.documents.count

                            if snap.documents.count == 0 {
                                self.loadingFinished()
                            }
                            
                            for document in snap.documents {
                                let data = document.data()
                                
                                if let fact = CommunityHelper().getCommunity(currentUser: user, documentID: document.documentID, data: data) {
                                    self.discussionFacts.append(fact)
                                } else {
                                    discussionCount-=1
                                }
                                
                                if self.discussionFacts.count == discussionCount {
                                    
                                    self.loadingFinished()
                                }
                            }
                        } else {
                            self.loadingFinished()
                        }
                    }
                }
                
            } else {
                self.view.activityStopAnimating()
                print("Something went wrong")
            } 
        }
    }
    
    func loadingFinished() {
        self.collectionView.reloadData()
        self.getFollowedCommunities()
        self.isLoading = false
        self.view.activityStopAnimating()
    }
    
    func getFollowedCommunities() {
        if let user = Auth.auth().currentUser {
            dataHelper.getFollowedTopicDocuments(userUID: user.uid) { (documents) in
                var topicCount = documents.count
                for document in documents {
                    self.addFact(user: user, document: document) { (fact) in
                        if let fact = fact {
                            fact.beingFollowed = true
                            self.followedFacts.append(fact)
                            self.followedFacts.sort {
                                $0.title.localizedCompare($1.title) == .orderedAscending //Not case sensitive
                            }
                        } else {
                            topicCount-=1
                        }
                        if self.followedFacts.count == topicCount {
                            self.collectionView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func addFact(user: Firebase.User?, document: QueryDocumentSnapshot, returnedFact: @escaping (Community?) -> Void) {
        let data = document.data()
        
        var collectionRef: CollectionReference = self.db.collection("Facts")
        
        if let language = data["language"] as? String {
            if language == "en" {
                collectionRef = self.db.collection("Data").document("en").collection("topics")
            }
        }
        
        let ref = collectionRef.document(document.documentID)
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                returnedFact(nil)
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let fact = CommunityHelper().getCommunity(currentUser: user, documentID: snap.documentID, data: data) {
                            returnedFact(fact)
                        }
                    } else {
                        returnedFact(nil)
                    }
                } else {
                    returnedFact(nil)
                }
            }
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        //To update the "currentTopic" Cell
        for cell in collectionView.visibleCells {
            let indexPath = collectionView.indexPath(for: cell)
            
            if indexPath == IndexPath(item: 0, section: 0) {
                if self.reloadRecentTopics {
                    if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? RecentTopicsCollectionCell {
                        cell.getFacts(initialFetch: false)
                        self.reloadRecentTopics = false
                    } else {
                        print("still cant find cell")
                    }
                }
            }
        }
    }
    
    //MARK: -Recent Topics
    
    func topicSelected(fact: Community) {
        print("TopicSelected")
        registerRecentFact(fact: fact)
    }
    
    func registerRecentFact(fact: Community) {
        // Safe the selected topic to display it later in the "currentTopic" CollectionView
        let defaults = UserDefaults.standard
        let key:String!
        switch fact.language {
        case .english:
            key = "recentTopics-en"
        case .german:
            key = "recentTopics"
        }
        
        var factStrings = defaults.stringArray(forKey: key) ?? [String]()
        
        factStrings = factStrings.filter{ $0 != fact.documentID }
        factStrings.insert(fact.documentID, at: 0)
        
        if factStrings.count >= 10 {
            factStrings.removeLast()
        }
        
        defaults.set(factStrings, forKey: key)
        
        reloadRecentTopics = true
    }
    
    //MARK: - PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPageVC" {
            if let pageVC = segue.destination as? CommunityPageVC {
                if let chosenCommunity = sender as? Community {
                    pageVC.community = chosenCommunity
                    pageVC.recentTopicDelegate = self
                }
            }
        }
        
        if segue.identifier == "toNewArgumentSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newFactVC = navCon.topViewController as? NewCommunityItemTableVC {
                    if let type = sender as? DisplayOption {
                        
                        newFactVC.pickedDisplayOption = type
                        
                        newFactVC.new = .community
                        newFactVC.delegate = self
                    }
                }
            }
        }
        if segue.identifier == "showAllTopicsSegue" {
            if let showAllVC = segue.destination as? AllCommunitiesCollectionVC {
                if let type = sender as? DisplayOption {
                    showAllVC.type = type
                }
            }
        }
    }
    


    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
            self.tipView = nil
        } else {
            tipView = EasyTipView(text: Constants.texts.factOverviewText)
            tipView!.show(forItem: infoButton)
        }
    }
    
    //MARK: LinkFactAndPost
    
    func setFactForPost(fact: Community) {
        delegate?.selectedFact(fact: fact, isViewAlreadyLoaded: true) // True because 
        
        //Can be a opt. Info!
        self.dismiss(animated: true, completion: nil)
    }
    
    func setFactForOptInfo(fact: Community) {
        if let addOn = addOn {
            addOn.delegate = self
            addOn.saveItem(item: fact)
        }
    }
}

extension CommunityCollectionVC: AddOnDelegate {
    func fetchCompleted() {
        print("not needed")
    }
    
    func itemAdded(successfull: Bool) {
        if successfull {
            addItemDelegate?.itemAdded()
            self.navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController(title: "Something went wrong", message: "Please try later again or ask the developers to do a better job. We are sorry!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true)
        }
    }
}

extension CommunityCollectionVC: TopOfCollectionViewDelegate, NewFactDelegate, TopicCollectionFooterDelegate, RecentTopicCellDelegate {
    
    //Topic in the recentTopic collectionView is tapped
    func topicTapped(fact: Community) {
        
        if let addFactToPost = addFactToPost {
            if addFactToPost == .newPost {
                self.setFactForPost(fact: fact)
            } else {
                self.setFactForOptInfo(fact: fact)
            }
        } else {
            performSegue(withIdentifier: "toPageVC", sender: fact)
        }
    }
    
    func addTopicTapped(type: DisplayOption) {
        performSegue(withIdentifier: "toNewArgumentSegue", sender: type)
    }
    
    func showAllTapped(type: DisplayOption) {
        performSegue(withIdentifier: "showAllTopicsSegue", sender: type)
    }
    
    func finishedCreatingNewInstance(item: Any?) {
        if let fact = item as? Community {
            performSegue(withIdentifier: "toPageVC", sender: fact)
        }
    }
    
    
    func sortFactsTapped(option: FactCollectionDisplayOption) {
        
//        self.displayOption = option
        collectionView.reloadData()
    }
}


class AddTopicCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var plusWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusLineStrength: NSLayoutConstraint!
    @IBOutlet weak var plusLineStrength2: NSLayoutConstraint!
    
    
    var isAddOnView: Bool? {
        didSet {
            if isAddOnView! {
                textLabel.text = NSLocalizedString("add_item_label", comment: "add item")
                textLabel.font =  UIFont(name: "IBMPlexSans-Medium", size: 13)
                plusHeightConstraint.constant = 35
                plusWidthConstraint.constant = 35
                plusLineStrength.constant = 3
                plusLineStrength2.constant = 3
                
                layer.borderWidth = 0
            }
        }
    }
    
    override func awakeFromNib() {
        layer.cornerRadius = 4
        layer.masksToBounds = true
        layer.borderColor = UIColor.label.cgColor
        layer.borderWidth = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let _ = isAddOnView {
            let eigth: CGFloat = self.contentView.frame.width/8
            let margins = UIEdgeInsets(top: eigth, left: eigth, bottom: eigth, right: eigth)
            contentView.frame = contentView.frame.inset(by: margins)
        }
    }
    
}

class ShowAllTopicsCell: UICollectionViewCell {
    
    
    override func awakeFromNib() {
        layer.cornerRadius = 4
        layer.masksToBounds = true
        layer.borderColor = UIColor.label.cgColor
        layer.borderWidth = 0.5
    }
    
}


class FirstCollectionHeader: UICollectionReusableView {
    @IBOutlet weak var headerLabel: UILabel!
    
}

class FactCollectionHeader: UICollectionReusableView {
    @IBOutlet weak var sortFactsButton: DesignableButton!
    
    var delegate: TopOfCollectionViewDelegate?
    var displayOption: FactCollectionDisplayOption = .all
    
    @IBAction func sortFactsTapped(_ sender: Any) {
                
        switch self.displayOption {
        case .all:
            self.displayOption = .justTopics
            sortFactsButton.setTitle("Nur Themen", for: .normal)
        case .justTopics:
            self.displayOption = .justFacts
            sortFactsButton.setTitle("Nur Diskussionen", for: .normal)
        case .justFacts:
            self.displayOption = .all
            sortFactsButton.setTitle("Alle", for: .normal)
        }
        
        delegate?.sortFactsTapped(option: self.displayOption)
    }
}

class TopicCollectionHeader: UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    
}
