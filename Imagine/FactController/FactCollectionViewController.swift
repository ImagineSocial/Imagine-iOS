//
//  FactCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import EasyTipView

private let factCellIdentifier = "FactCell"

protocol LinkFactWithPostDelegate {
    func selectedFact(fact: Fact, isViewAlreadyLoaded: Bool)
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

class FactCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RecentTopicDelegate {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var topicFacts = [Fact]()
    var discussionFacts = [Fact]()
    var filteredFacts = [Fact]()
    var followedFacts = [Fact]()
    
//    var displayOption: FactCollectionDisplayOption = .all
    
    let db = Firestore.firestore()
    let dataHelper = DataHelper()
    
    var addFactToPost : AddFactToPostType?
    var delegate: LinkFactWithPostDelegate?
    var addItemDelegate: AddItemDelegate?
    
    var tipView: EasyTipView?
    
    let collectionViewSpacing:CGFloat = 30
    let searchController = UISearchController(searchResultsController: nil)
    
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
//        setUpSearchController()
        
        if addFactToPost == .newPost {
            self.setDismissButton()
        }
        
        collectionView.register(UINib(nibName: "TopicCollectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: topicHeaderIdentifier)
        collectionView.register(UINib(nibName: "TopicCollectionFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: topicFooterIdentifier)
        collectionView.register(UINib(nibName: "FactCell", bundle: nil), forCellWithReuseIdentifier: factCellIdentifier)
        collectionView.register(UINib(nibName: "RecentTopicsCollectionCell", bundle: nil), forCellWithReuseIdentifier: recentTopicsCellIdentifier)
        collectionView.register(UINib(nibName: "DiscussionCell", bundle: nil), forCellWithReuseIdentifier: discussionCellIdentifier)
        collectionView.register(UINib(nibName: "FollowedTopicCell", bundle: nil), forCellWithReuseIdentifier: followedTopicCellIdentifier)
        collectionView.register(UINib(nibName: "PlaceHolderCell", bundle: nil), forCellWithReuseIdentifier: placeHolderIdentifier)
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.view.activityStartAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = true
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
        self.navigationController?.navigationBar.isTranslucent = false
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
        dataHelper.getData(get: .facts) { (facts) in
            
            if let facts = facts as? [Fact] {
                
                for fact in facts {
                    if fact.displayOption == .fact && self.discussionFacts.count < 6 {
                        self.discussionFacts.append(fact)
                    } else if fact.displayOption == .topic && self.topicFacts.count < 8  {
                        self.topicFacts.append(fact)
                    }
                }
                self.isLoading = false
                self.collectionView.reloadData()
                self.view.activityStopAnimating()
            } else {
                self.view.activityStopAnimating()
                print("Something went wrong")
            }
        }
        
        if let user = Auth.auth().currentUser {
            dataHelper.getFollowedTopicDocuments(userUID: user.uid) { (documents) in
                for document in documents {
                    self.addFact(documentID: document.documentID)
                }
            }
        }
    }
    
    func addFact(documentID: String) {
        let ref = self.db.collection("Facts").document(documentID)
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let fact = self.dataHelper.addFact(documentID: snap.documentID, data: data) {
                            fact.beingFollowed = true
                            self.followedFacts.append(fact)
                            self.followedFacts.sort {
                                $0.title.localizedCompare($1.title) == .orderedAscending //Not case sensitive
                            }
                            self.collectionView.reloadData()    //not the best idea i know
                        }
                    }
                }
            }
        }
    }
    
    func setUpSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Durchsuche die Themen..."
    
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 4
    }
    
  


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        } else if section == 1 {
            if isLoading {
                return 10
            } else {
                if isFiltering {
                    return filteredFacts.count
                } else {
                    return 10
                }
            }
        } else if section == 2 {
            return discussionFacts.count
        } else {
            return followedFacts.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var fact: Fact?
        
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
                if isFiltering {
                    fact = filteredFacts[indexPath.row]
                } else {
                    fact = topicFacts[indexPath.row]
                }
            }
        } else if  indexPath.section == 2 {
            fact = discussionFacts[indexPath.row]
            
            
        } else {
            fact = followedFacts[indexPath.row]
        }
        
        if let fact = fact {
            
            if indexPath.section == 1 {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: factCellIdentifier, for: indexPath) as? FactCell {
                    
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
        
        
        if indexPath.section == 0 {
            let newSize = CGSize(width: (collectionView.frame.size.width)-(collectionViewSpacing+10), height: (collectionView.frame.size.width/4))
            
            return newSize
        } else if  indexPath.section == 1 {    // normal Communities
            
                let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-collectionViewSpacing)
                
                return newSize
            
        } else if  indexPath.section == 2 { // Discussions
            
                let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-(collectionViewSpacing/2))
                
                return newSize
            
        } else {
            let newSize = CGSize(width: (collectionView.frame.size.width), height: 40)
            
            return newSize
        }
            
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var fact: Fact?
        
        if indexPath.section == 0 {
            
        } else if indexPath.section == 1 {
            if isFiltering {
                fact = filteredFacts[indexPath.row]
            } else {
                fact = topicFacts[indexPath.row]
            }
        } else if indexPath.section == 2 {
            fact = discussionFacts[indexPath.row]
        } else {
            fact = followedFacts[indexPath.row]
        }
        
        if let fact = fact {
            
            if let addFactToPost = addFactToPost{
                
                if addFactToPost == .newPost {
                    self.setFactForPost(fact: fact)
                } else {
                    let factString = fact.title.quoted
                    let alert = UIAlertController(title: "Bist du dir sicher?", message: "Möchtest du das Thema \(factString) zu dem AddOn hinzufügen?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (_) in
                        self.setFactForOptInfo(fact: fact)
                    }))
                    alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: { (_) in
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alert, animated: true)
                }
            } else {
                performSegue(withIdentifier: "toPageVC", sender: fact)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {  // View above CollectionView
            if indexPath.section == 0 {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "factCollectionFirstHeader", for: indexPath) as? FirstCollectionHeader {
                
                    if addFactToPost == .optInfo {
                        view.headerLabel.font = UIFont(name: "IBMPlexSans", size: 16)
                        view.headerLabel.numberOfLines = 0
                        view.headerLabel.text = "Wähle eines dieser Themen aus oder nutze die Suchfunktion"
                    }
                    return view
                }
            } else {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: topicHeaderIdentifier, for: indexPath) as? TopicCollectionHeader {
                    
                    if indexPath.section == 1 {
                        view.headerLabel.text = "Angesagt"
                    } else if indexPath.section == 2 {
                        view.headerLabel.text = "Aktuelle Diskussionen"
                    } else if indexPath.section == 3 {
                        view.headerLabel.text = "Deine Communities"
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
                        view.type = .fact
                    }
                    
                    return view
                }
            }
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: collectionView.frame.width, height: 70)
        } else {
            return CGSize(width: collectionView.frame.width, height: 50)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if section != 0 && section != 3 {
            return CGSize(width: collectionView.frame.width, height: 85)
        } else {
            return CGSize(width: collectionView.frame.width, height: 0)
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
    
    
    func logUser(fact: Fact) {
        if let user = Auth.auth().currentUser {
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                print("Nicht bei Malte loggen")
            } else {
                Analytics.logEvent("FactDetailOpened", parameters: [
                    AnalyticsParameterTerm: fact.title
                ])
            }
        } else {
            Analytics.logEvent("FactDetailOpened", parameters: [
                AnalyticsParameterTerm: fact.title
            ])
        }
    }
    
    //MARK: -Recent Topics
    
    func topicSelected(fact: Fact) {
        print("TopicSelected")
        registerRecentFact(fact: fact)
    }
    
    func registerRecentFact(fact: Fact) {
        // Safe the selected topic to display it later in the "currentTopic" CollectionView
         let defaults = UserDefaults.standard
         var factStrings = defaults.stringArray(forKey: "recentTopics") ?? [String]()
        
         factStrings = factStrings.filter{ $0 != fact.documentID }
         factStrings.insert(fact.documentID, at: 0)
         
         if factStrings.count >= 10 {
             factStrings.removeLast()
         }
         
         defaults.set(factStrings, forKey: "recentTopics")
        
        reloadRecentTopics = true
    }
    
    //MARK: -PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPageVC" {
            if let pageVC = segue.destination as? ArgumentPageViewController {
                if let chosenFact = sender as? Fact {
                    pageVC.fact = chosenFact
                    pageVC.recentTopicDelegate = self
                    
                    self.logUser(fact: chosenFact)
                }
            }
        }
        
        if segue.identifier == "toNewArgumentSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newFactVC = navCon.topViewController as? NewFactViewController {
                    if let type = sender as? DisplayOption {
                        
                        newFactVC.pickedDisplayOption = type
                        
                        newFactVC.new = .fact
                        newFactVC.delegate = self
                    }
                }
            }
        }
        if segue.identifier == "showAllTopicsSegue" {
            if let showAllVC = segue.destination as? ShowAllFactsCollectionViewController {
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
    
    func setFactForPost(fact: Fact) {
        delegate?.selectedFact(fact: fact, isViewAlreadyLoaded: true) // True because 
        
        //Can be a opt. Info!
        closeAndDismiss()
    }
    
    func setFactForOptInfo(fact: Fact) {
        addItemDelegate?.itemSelected(item: fact)
        
        if searchController.isActive {
            searchController.dismiss(animated: false) {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func closeAndDismiss() {
        if searchController.isActive {
            searchController.dismiss(animated: false) {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    //MARK: -Search functionality
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String ){
        
        let titleRef = db.collection("Facts").whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)ü").limit(to: 10)
        
        titleRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.filteredFacts.removeAll()
                for document in snap!.documents {
                    let documentData = document.data()
                    let documentID = document.documentID
                    
                    guard let name = documentData["name"] as? String,
                        let createTimestamp = documentData["createDate"] as? Timestamp
                        else {
                            continue
                    }
                    
                    let date = createTimestamp.dateValue()
                    let stringDate = date.formatRelativeString()
                    
                    let fact = Fact()
                    fact.title = name
                    fact.createDate = stringDate
                    fact.documentID = documentID
                    
                    if let displayOption = documentData["displayOption"] as? String {
                        if displayOption == "topic" {
                            fact.displayOption = .topic
                        } else {
                            fact.displayOption = .fact
                        }
                    }
                    
                    if let imageURL = documentData["imageURL"] as? String {
                        fact.imageURL = imageURL
                    }
                    if let description = documentData["description"] as? String {
                        fact.description = description
                    }
                    
                    self.filteredFacts.append(fact)
                }
                self.collectionView.reloadData()
            }
        }
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
}

extension FactCollectionViewController: TopOfCollectionViewDelegate, NewFactDelegate, TopicCollectionFooterDelegate, RecentTopicCellDelegate {
    
    //Topic in the recentTopic collectionView is tapped
    func topicTapped(fact: Fact) {
        
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
        self.topicFacts.removeAll()
        self.discussionFacts.removeAll()
        self.collectionView.reloadData()
        
        self.getFacts()
    }
    
    
    func sortFactsTapped(option: FactCollectionDisplayOption) {
        
//        self.displayOption = option
        collectionView.reloadData()
    }
}
    


extension FactCollectionViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let searchBar = searchController.searchBar
    filterContentForSearchText(searchBar.text!)
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
                textLabel.text = "Neues Item hinzufügen"
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
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
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
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
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

