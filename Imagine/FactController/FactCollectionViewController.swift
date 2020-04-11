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

enum AddFactToPostType {
    case optInfo
    case newPost
}

class FactCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, RecentTopicCellDelegate, RecentTopicDelegate {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var facts = [Fact]()
    var topicFacts = [Fact]()
    var factFacts = [Fact]()
    var filteredFacts = [Fact]()
    
    var displayOption: FactCollectionDisplayOption = .all
    
    let db = Firestore.firestore()
    
    var addFactToPost : AddFactToPostType?
    var delegate: LinkFactWithPostDelegate?
    var addItemDelegate: AddItemDelegate?
    
//    var optionalInformationType: OptionalInformationType = .guilty
    
    let collectionViewSpacing:CGFloat = 30
    let searchController = UISearchController(searchResultsController: nil)
    
    let secondHeaderIdentifier = "collectionViewView"
    let recentTopicsCellIdentifier = "RecentTopicsCollectionCell"
    
    var reloadRecentTopics = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFacts()
        setUpSearchController()
        
        if addFactToPost == .newPost {
            self.setDismissButton()
        }
        
        collectionView.register((UINib(nibName: "FactCollectionHeader", bundle: nil)), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: secondHeaderIdentifier)
        collectionView.register(UINib(nibName: "FactCell", bundle: nil), forCellWithReuseIdentifier: factCellIdentifier)
        collectionView.register(UINib(nibName: "RecentTopicsCollectionCell", bundle: nil), forCellWithReuseIdentifier: recentTopicsCellIdentifier)
        collectionView.register(UINib(nibName: "AddTopicCell", bundle: nil), forCellWithReuseIdentifier: "AddTopicCell")
        
        extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.navigationBar.shadowImage = UIImage()
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.backgroundColor = .systemBackground
        } else {
            self.navigationController?.navigationBar.backgroundColor = .white
        }
        
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
        searchController.searchBar.placeholder = "Durchsuche die Themen..."
    
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
                    if chosenFact.displayMode == .topic {
                        pageVC.displayMode = .topic
                    }
                    
                    self.logUser(fact: chosenFact)
                }
            }
        }
        
        if segue.identifier == "toNewArgumentSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let newFactVC = navCon.topViewController as? NewFactViewController {
                    newFactVC.new = .fact
                    newFactVC.delegate = self
                }
            }
        }
    }
    


    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.factOverviewText)
    }
    
    //MARK: LinkFactAndPost
    
    func setFactForPost(fact: Fact) {
        delegate?.selectedFact(fact: fact, closeMenu: true)
        
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

extension FactCollectionViewController: TopOfCollectionViewDelegate, NewFactDelegate {
    func finishedCreatingNewInstance(item: Any?) {
        self.facts.removeAll()
        self.collectionView.reloadData()
        
        self.getFacts()
    }
    
    
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
            sortFactsButton.setTitle("Nur Fakten", for: .normal)
        case .justFacts:
            self.displayOption = .all
            sortFactsButton.setTitle("Alle", for: .normal)
        }
        
        delegate?.sortFactsTapped(option: self.displayOption)
    }
}
