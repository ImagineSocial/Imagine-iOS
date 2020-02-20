//
//  FactCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

private let factCellIdentifier = "FactCell"

protocol LinkFactWithPostDelegate {
    func selectedFact(fact: Fact, closeMenu: Bool)
}

protocol TopOfCollectionViewDelegate {
    func sortFactsTapped(option: FactCollectionDisplayOption)
}

enum FactCollectionDisplayOption {
    case all
    case justFacts
    case justTopics
}

class FactCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RecentTopicCellDelegate, RecentTopicDelegate {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var facts = [Fact]()
    var topicFacts = [Fact]()
    var factFacts = [Fact]()
    var filteredFacts = [Fact]()
    
    var displayOption: FactCollectionDisplayOption = .all
    
    let db = Firestore.firestore()
    
    var addFactToPost = false
    var delegate: LinkFactWithPostDelegate?
    
    let collectionViewSpacing:CGFloat = 30
    let searchController = UISearchController(searchResultsController: nil)
    
    let secondHeaderIdentifier = "collectionViewView"
    let recentTopicsCellIdentifier = "RecentTopicsCollectionCell"
    
    var reloadRecentTopics = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFacts()
        setUpSearchController()
        
        if addFactToPost {
            self.setDismissButton()
        }
        
        collectionView.register((UINib(nibName: "FactCollectionHeader", bundle: nil)), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: secondHeaderIdentifier)
        collectionView.register(UINib(nibName: "FactCell", bundle: nil), forCellWithReuseIdentifier: factCellIdentifier)
        collectionView.register(UINib(nibName: "RecentTopicsCollectionCell", bundle: nil), forCellWithReuseIdentifier: recentTopicsCellIdentifier)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.backgroundColor = .systemBackground
        } else {
            self.navigationController?.navigationBar.backgroundColor = .white
        }
        
        self.view.activityStartAnimating()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //FML
        self.navigationController?.navigationBar.isTranslucent = true
        
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
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Constants.imagineColor
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
        DataHelper().getData(get: .facts) { (facts) in
            
            if let facts = facts as? [Fact] {
                self.facts = facts
                
                for fact in facts {
                    if fact.displayMode == .fact {
                        self.factFacts.append(fact)
                    } else {
                        self.topicFacts.append(fact)
                    }
                }
                
                let fact = Fact(addMoreDataCell: true)
                self.facts.append(fact)
                self.factFacts.append(fact)
                self.topicFacts.append(fact)
                
                self.collectionView.reloadData()
                self.view.activityStopAnimating()
            } else {
                self.view.activityStopAnimating()
                print("Something went wrong")
            }
        }
    }
    
    func setUpSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Suche nach Fakten"
    
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
  


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        } else {
            if isFiltering {
                return filteredFacts.count
            } else {
                
                switch displayOption {
                case .all:
                    return facts.count
                case .justTopics:
                    return topicFacts.count
                case .justFacts:
                    return factFacts.count
                }
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var fact: Fact?
        
        if indexPath.section == 0 { // First wide cell for recentTopics
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: recentTopicsCellIdentifier, for: indexPath) as? RecentTopicsCollectionCell {
                
                cell.delegate = self
                
                return cell
            }
        } else {    //Other cells
            
            if isFiltering {
                fact = filteredFacts[indexPath.row]
            } else {
                
                switch displayOption {
                case .all:
                    fact = facts[indexPath.row]
                case .justTopics:
                    fact = topicFacts[indexPath.row]
                case .justFacts:
                    fact = factFacts[indexPath.row]
                }
            }
            
            if fact!.addMoreCell {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddTopicCell", for: indexPath) as? AddTopicCell {
                    
                    let layer = cell.layer
                    layer.cornerRadius = 4
                    layer.masksToBounds = true
                    if #available(iOS 13.0, *) {
                        layer.borderColor = UIColor.label.cgColor
                    } else {
                        layer.borderColor = UIColor.black.cgColor
                    }
                    layer.borderWidth = 1
                    
                    return cell
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: factCellIdentifier, for: indexPath) as? FactCell {
                    
                    cell.fact = fact!
                    
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
        } else {
            let newSize = CGSize(width: (collectionView.frame.size.width/2)-collectionViewSpacing, height: (collectionView.frame.size.width/2)-collectionViewSpacing)
            
            return newSize
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        var fact: Fact?
        
        if isFiltering {
            fact = filteredFacts[indexPath.row]
        } else {
            switch displayOption {
            case .all:
                fact = facts[indexPath.row]
            case .justTopics:
                fact = topicFacts[indexPath.row]
            case .justFacts:
                fact = factFacts[indexPath.row]
            }
        }
        
        if let fact = fact {
            if fact.addMoreCell {
                performSegue(withIdentifier: "toNewArgumentSegue", sender: nil)
            } else {
                if self.addFactToPost {
                    self.setFactForPost(fact: fact)
                } else {
                    
                    if fact.displayMode == .fact {
                        performSegue(withIdentifier: "goToArguments", sender: fact)
                    } else {
                        performSegue(withIdentifier: "goToPostsOfTopic", sender: fact)
                    }
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {  // View above CollectionView
            if indexPath.section == 0 {
                let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "factCollectionFirstHeader", for: indexPath)
                
                return view
            } else {
                if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: secondHeaderIdentifier, for: indexPath) as? FactCollectionHeader {
                    
                    view.delegate = self
                    
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
            return CGSize(width: collectionView.frame.width, height: 20)
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        //To update the "currentTopic" Cell
        for cell in collectionView.visibleCells {
            let indexPath = collectionView.indexPath(for: cell)
            
            if indexPath == IndexPath(item: 0, section: 0) {
                print("Is the right indexpath")
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
    //Topic in the recentTopic collectionView is tapped
    func topicTapped(fact: Fact) {
        
        if fact.displayMode == .fact {
            performSegue(withIdentifier: "goToArguments", sender: fact)
        } else {
            performSegue(withIdentifier: "goToPostsOfTopic", sender: fact)
        }
    }
    
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
        if segue.identifier == "goToArguments" {
            if let fact = sender as? Fact {
                if let argumentVC = segue.destination as? FactParentContainerViewController {
                    argumentVC.fact = fact
                    argumentVC.delegate = self
                    
                    self.logUser(fact: fact)
                }
            }
        }
        
        if segue.identifier == "goToPostsOfTopic" {
            if let fact = sender as? Fact {
                if let nextVC = segue.destination as? PostsOfFactTableViewController {
                    nextVC.fact = fact
                    nextVC.delegate = self
                    self.logUser(fact: fact)
                }
            }
        }
        
        if segue.identifier == "toNewArgumentSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newFactVC = navCon.topViewController as? NewFactViewController {
                    newFactVC.new = .fact
                }
            }
        }
    }

    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.factOverviewText)
    }
    
    //MARK: LinkFactAndPost
    
    func setFactForPost(fact: Fact) {
        print("Set delegate: ", fact.title)
        delegate?.selectedFact(fact: fact, closeMenu: true)
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
                    
                    let fact = Fact(addMoreDataCell: false)
                    fact.title = name
                    fact.createDate = stringDate
                    fact.documentID = documentID
                    
                    if let displayOption = documentData["displayOption"] as? String {
                        switch displayOption {
                        case "topic":
                            fact.displayMode = .topic
                        default:
                            fact.displayMode = .fact
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
                let fact = Fact(addMoreDataCell: true)
                self.filteredFacts.append(fact)
                self.collectionView.reloadData()
            }
        }
    }
    
    var isFiltering: Bool {
      return searchController.isActive && !isSearchBarEmpty
    }
}

extension FactCollectionViewController: TopOfCollectionViewDelegate {
    
    func sortFactsTapped(option: FactCollectionDisplayOption) {
        
        self.displayOption = option
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
            sortFactsButton.setTitle("Nur Fakten", for: .normal)
        case .justFacts:
            self.displayOption = .all
            sortFactsButton.setTitle("Alle", for: .normal)
        }
        
        delegate?.sortFactsTapped(option: self.displayOption)
    }
}
