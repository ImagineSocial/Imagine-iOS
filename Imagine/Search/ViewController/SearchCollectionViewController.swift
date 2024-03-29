//
//  SearchCollectionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import AVKit

class SearchCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let db = FirestoreRequest.shared.db
    let handyHelper = HandyHelper.shared
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var postResults: [Post]?
    var userResults: [User]?
    var topicResults: [Community]?
    
    var communityPosts: [Post]? // Default topicPosts queried by date and type
    var communityPostsStack: [Post]?
    
    let postCellIdentifier = "SmallPostCell"
    let topicCellIdentifier = "FactCell"
    let userCellIdentifier = "SearchUserCell"
    
    var headerDelegate: SearchCollectionViewHeaderDelegate?
    
    let communityPostCellIdentifier = "SearchCollectionViewPostCell"
    let searchHeaderIdentifier = "SearchCollectionViewHeader"
    let placeHolderIdentifier = "PlaceHolderCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib(nibName: "SmallPostCell", bundle: nil), forCellWithReuseIdentifier: postCellIdentifier)
        collectionView.register(UINib(nibName: "FactCell", bundle: nil), forCellWithReuseIdentifier: topicCellIdentifier)
        collectionView.register(SearchUserCell.self, forCellWithReuseIdentifier: userCellIdentifier)
        collectionView.register(UINib(nibName: "PlaceHolderCell", bundle: nil), forCellWithReuseIdentifier: placeHolderIdentifier)
        collectionView.layoutIfNeeded()
        collectionView.setNeedsLayout()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        extendedLayoutIncludesOpaqueBars = true
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
        }
        
        setUpSearchController()
        getCommunityPosts()
    }
    
    func setUpSearchController() {
        
        // I think it is unnecessary to set the searchResultsUpdater and searchcontroller Delegate here, but I couldnt work out an alone standing SearchViewController
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("search_input_placeholder", comment: "search for user, communities and posts")
        searchController.delegate = self
        
        searchController.searchBar.scopeButtonTitles = ["Posts", "Communities", "User"]
        searchController.searchBar.delegate = self
        
        self.navigationItem.searchController = searchController
        
        self.navigationItem.hidesSearchBarWhenScrolling = true
        searchController.isActive = true
        definesPresentationContext = true
    }
    
    
    
    func getCommunityPosts() {
        DispatchQueue.global(qos: .background).async {
            
            let collectionRef = FirestoreReference.collectionRef(.topicPosts)
            
            let query = collectionRef.whereField("type", in: ["picture", "multiPicture", "GIF"]).order(by: "createdAt", descending: true).limit(to: 30)

            FirestoreManager.shared.decode(query: query) { (result: Result<[Post], Error>) in
                switch result {
                case .success(let posts):
                    DispatchQueue.main.async {
                        self.communityPosts = posts
                        self.collectionView.reloadData()
                    }
                case .failure(let error):
                    print("We have an error: \(error.localizedDescription)")
                }
            }
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let posts = communityPosts {
            return posts.count
        } else if let posts = postResults {
            return posts.count
        } else if let users = userResults {
            return users.count
        } else if let topics = topicResults {
            return topics.count
        } else {
            return 15
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let posts = communityPosts {
            let post = posts[indexPath.item]
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: communityPostCellIdentifier, for: indexPath) as? SearchCollectionViewPostCell {
                
                cell.post = post
                
                return cell
            }
            
        } else if let posts = postResults {
            let post = posts[indexPath.item]
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: postCellIdentifier, for: indexPath) as? SmallPostCell {
                
                cell.post = post
                cell.optionalTitleGradientView.isHidden = true
                
                return cell
            }
            
        } else if let users = userResults {
            let user = users[indexPath.item]
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: userCellIdentifier, for: indexPath) as? SearchUserCell {
                
                cell.user = user
                
                return cell
            }
            
        } else if let topics = topicResults {
            let community = topics[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: topicCellIdentifier, for: indexPath) as? FactCell {
                
                cell.community = community
                
                return cell
            }
            
        } else {
            // Blank Cell
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: placeHolderIdentifier, for: indexPath) as? PlaceHolderCell {
                
                
                return cell
            }
        }
            
        return collectionView.dequeueReusableCell(withReuseIdentifier: "reuseIdentifier", for: indexPath)
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.view.frame.width
        
        
        if communityPosts != nil {
            return CGSize(width: (width-2)/3, height: (width-2)/3)
        } else if postResults != nil {
            return CGSize(width: (width/2)-1, height: (width/2)-1)
        } else if topicResults != nil {
            return CGSize(width: (width/2)-1, height: (width/2)-1)
        } else if userResults != nil {
            return CGSize(width: width, height: 65)
        } else {
            return CGSize(width: (width-2)/3, height: (width-2)/3)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let posts = communityPosts {
            let post = posts[indexPath.item]
            performSegue(withIdentifier: "toPostSegue", sender: post)
        } else if let posts = postResults {
            let post = posts[indexPath.item]
            performSegue(withIdentifier: "toPostSegue", sender: post)
        } else if let topics = topicResults {
            let fact = topics[indexPath.item]
            performSegue(withIdentifier: "toTopicSegue", sender: fact)
        } else if let users = userResults {
            let user = users[indexPath.item]
            performSegue(withIdentifier: "toUserSegue", sender: user)
        } else {
            print("What was selectedd?")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "toPostSegue":
            if let vc = segue.destination as? PostViewController, let post = sender as? Post {
                vc.post = post
                vc.navigationItem.largeTitleDisplayMode = .never
            }
        case "toTopicSegue":
            if let pageVC = segue.destination as? CommunityPageVC, let chosenCommunity = sender as? Community {
                pageVC.community = chosenCommunity
            }
        case "toUserSegue":
            if let userVC = segue.destination as? UserFeedTableViewController, let user = sender as? User {
                userVC.user = user
                userVC.currentState = .otherUser
            }
        default:
            break
        }
    }
}

//MARK: -SearchController

extension SearchCollectionViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        searchController.searchResultsController?.view.isHidden = false
        
        let searchBar = searchController.searchBar
        let scope = searchBar.selectedScopeButtonIndex
        
        if searchBar.text! != "" {
            searchTheDatabase(searchText: searchBar.text!, searchScope: scope)
            changeTitleOfHeader(scope: scope)
        } else {
            // Clear the searchTableView
            showBlankTableView()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        changeTitleOfHeader(scope: selectedScope)
    }
    
    func changeTitleOfHeader(scope: Int) {
        switch scope {
        case 0:
            headerDelegate?.newHeaderText(text: NSLocalizedString("posts", comment: "posts"))
        case 1:
            headerDelegate?.newHeaderText(text: "Communities:")
        default:
            headerDelegate?.newHeaderText(text: "User:")
        }
    }
    
    func showBlankTableView() {
        
        postResults = nil
        userResults = nil
        topicResults = nil
        
        if let posts = communityPostsStack {
            communityPosts = posts
        }
        headerDelegate?.newHeaderText(text: NSLocalizedString("search_input_header", comment: "community posts:"))
        
        collectionView.reloadData()
    }
    
    func searchTheDatabase(searchText: String, searchScope: Int) {
        var postResults = [Post]()
        var userResults = [User]()
        var topicResults = [Community]()
        
        switch searchScope {
        case 0: // Search Posts
            let collectionRef = FirestoreReference.collectionRef(.posts)
            
            let searchQuery = collectionRef.whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            
            FirestoreManager.shared.decode(query: searchQuery) { (result: Result<[Post], Error>) in
                switch result {
                case .success(let posts):
                    postResults.append(contentsOf: posts)
                    
                    self.stackCommunityPosts()
                    self.communityPosts = nil
                    self.postResults = postResults
                    self.userResults = nil
                    self.topicResults = nil
                    self.collectionView.reloadData()
                case .failure(let error):
                    print("We have an error searching for titles: \(error.localizedDescription)")
                }
            }
            
            let topicCollectionRef = FirestoreReference.collectionRef(.topicPosts)
            
            let topicSearchQuery = topicCollectionRef.whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            
            FirestoreManager.shared.decode(query: topicSearchQuery) { (result: Result<[Post], Error>) in
                switch result {
                case .success(let posts):
                    postResults.append(contentsOf: posts)
                    
                    self.stackCommunityPosts()
                    self.communityPosts = nil
                    self.postResults = postResults
                    self.userResults = nil
                    self.topicResults = nil
                    self.collectionView.reloadData()
                case .failure(let error):
                    print("We have an error searching for titles: \(error.localizedDescription)")
                }
            }
        case 1:
            let collectionRef = FirestoreReference.collectionRef(.communities)
            
            let titleRef = collectionRef.whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)ü").limit(to: 10)
                        
            titleRef.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    
                    for document in snap!.documents {
                        addTopic(document: document)
                    }
                    
                    self.stackCommunityPosts()
                    
                    self.communityPosts = nil
                    self.postResults = nil
                    self.userResults = nil
                    self.topicResults = nil
                    self.topicResults = topicResults
                    self.collectionView.reloadData()
                }
            }
            
        case 2: // Search Users
            let fullNameRef = db.collection("Users").whereField("full_name", isGreaterThan: searchText).whereField("full_name", isLessThan: "\(searchText)ü").limit(to: 3)
            
            fullNameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        addUser(document: document)
                    }
                    
                    self.stackCommunityPosts()
                    
                    self.communityPosts = nil
                    self.userResults = nil
                    self.postResults = nil
                    self.userResults = userResults
                    self.topicResults = nil
                    self.collectionView.reloadData()
                }
            }
            
            let nameRef = db.collection("Users").whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)ü").limit(to: 3)
            
            nameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        addUser(document: document)
                    }
                    
                    self.stackCommunityPosts()
                    
                    self.communityPosts = nil
                    self.postResults = nil
                    self.userResults = userResults
                    self.topicResults = nil
                    self.collectionView.reloadData()
                }
            }
            
            let surnameRef = db.collection("Users").whereField("surname", isGreaterThan: searchText).whereField("surname", isLessThan: "\(searchText)ü").limit(to: 3)
            
            surnameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addUser(document: document)
                    }
                    
                    self.stackCommunityPosts()
                    
                    self.communityPosts = nil
                    self.topicResults = nil
                    self.postResults = nil
                    self.userResults = userResults
                    self.collectionView.reloadData()
                }
            }
        default:
            return
        }
        
        
        func addUser(document: DocumentSnapshot) {
            
            if userResults.contains(where: { $0.uid == document.documentID }) {   // Check if we got the user in on of the other queries
                return
            }
            
            AuthenticationManager.shared.generateUser(document: document) { user in
                if let user = user {
                    userResults.append(user)
                }
            }
        }
        
        
        func addTopic(document: DocumentSnapshot) {
            
            if topicResults.contains(where: { $0.id == document.documentID }) {
                return
            }
            
            guard let documentData = document.data(), let name = documentData["name"] as? String,
                  let timestamp = documentData["createdAt"] as? Timestamp
            else {
                return
            }
                        
            let community = Community()
            community.title = name
            community.createdAt = timestamp.dateValue()
            community.id = document.documentID
            community.imageURL = documentData["imageURL"] as? String
            community.description = documentData["description"] as? String
            
            if let displayOption = documentData["displayOption"] as? String {
                community.displayOption = displayOption == "topic" ? .topic : .discussion
            }
            
            topicResults.append(community)
        }
    }
    
    
    
    func stackCommunityPosts() {
        if self.communityPostsStack == nil {
            if let posts = self.communityPosts {
                self.communityPostsStack = posts
            }
        }
    }
}


//MARK:-SearchCOllectionCell & Header

protocol SearchCollectionViewHeaderDelegate {
    func newHeaderText(text: String)
}

class SearchCollectionViewHeader: UICollectionReusableView, SearchCollectionViewHeaderDelegate {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    func newHeaderText(text: String) {
        headerLabel.text = text
    }
    
}



class PlaceHolderCell: UICollectionViewCell {
    
}
