//
//  SearchTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol CustomSearchViewControllerDelegate {
    func didSelectItem(item: Any)
}

class SearchTableViewController: UITableViewController, UISearchControllerDelegate {
    
    let db = FirestoreRequest.shared.db
    let handyHelper = HandyHelper.shared
    let postHelper = PostHelper.shared
    
    var postResults: [Post]?
    var userResults: [User]?
    
    var searchController = UISearchController(searchResultsController: nil)
    
    let blankCellReuseIdentifier = "NibBlankCell"
    
    var customDelegate: CustomSearchViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SearchPostCell.self, forCellReuseIdentifier: "SearchPostCell")
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: blankCellReuseIdentifier)
                
//        setUpSearchController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func setUpSearchController() {
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Durchsuche Imagine"
        searchController.delegate = self
        
        searchController.searchBar.scopeButtonTitles = ["Posts", "User"]
        searchController.searchBar.delegate = self
        
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.searchController.isActive = true
        
        self.searchController.searchBar.becomeFirstResponder()
        definesPresentationContext = true
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let users = userResults {
            return users.count
        } else if let posts = postResults {
            return posts.count
        } else {
            return 1
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let posts = postResults {
            let post = posts[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPostCell", for: indexPath) as? SearchPostCell {
                
                cell.post = post
                
                return cell
            }
            
        } else if let _ = userResults {
//            let user = users[indexPath.row]
//            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserCell", for: indexPath) as? SearchUserCell {
//                
//                cell.user = user
//                
//                return cell
//            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: blankCellReuseIdentifier, for: indexPath) as? BlankContentCell {
                
                cell.type = .search
                cell.contentView.backgroundColor = self.tableView.backgroundColor
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let posts = postResults {
            let item = posts[indexPath.row]
            
            customDelegate?.didSelectItem(item: item)
        } else if let users = userResults {
            let item = users[indexPath.row]
            
            customDelegate?.didSelectItem(item: item)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let _ = postResults {
            return 75
        } else if let _ = userResults {
            return 75
        } else {
            return self.view.frame.height
        }
    }
    
    func showBlankTableView() {
        postResults = nil
        userResults = nil
        tableView.reloadData()
    }
    
}

extension SearchTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
        
        let searchBar = searchController.searchBar
        let scope = searchBar.selectedScopeButtonIndex
        
        if searchBar.text! != "" {
            searchTheDatabase(searchText: searchBar.text!, searchScope: scope, musicTrackOnly: false)
        } else {
            // Clear the searchTableView
            self.postResults = nil
            self.userResults = nil
            self.tableView.reloadData()
            
        }
    }
    
    func searchTheDatabase(searchText: String, searchScope: Int, musicTrackOnly: Bool) {
        var postResults = [Post]()
        var userResults = [User]()
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        
        switch searchScope {
        case 0: // Search Posts
            if language == .english {
                collectionRef = self.db.collection("Data").document("en").collection("posts")
            } else {
                collectionRef = self.db.collection("Posts")
            }
            
            let titleRef: Query!
            if musicTrackOnly {
                titleRef = collectionRef.whereField("musicType", isEqualTo: "track").whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            } else {
                titleRef = collectionRef.whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            }
            
            titleRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addPost(document: document, isTopicPost: false)
                    }
                    self.postResults = nil
                    self.postResults = postResults
                    self.userResults = nil
                    self.tableView.reloadData()
                }
            }
            
            
            // You have to write the whole noun
            let tagRef = collectionRef.whereField("tags", arrayContains: searchText).limit(to: 10)
            
            tagRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addPost(document: document, isTopicPost: false)
                    }
                    
                    self.postResults = nil
                    self.postResults = postResults
                    self.userResults = nil
                    self.tableView.reloadData()
                    
                    
                }
            }
        case 1: // Search Users
            let fullNameRef = db.collection("Users").whereField("full_name", isGreaterThan: searchText).whereField("full_name", isLessThan: "\(searchText)ü").limit(to: 3)
            
            fullNameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        addUser(document: document)
                    }
                    self.postResults = nil
                    self.userResults = userResults
                    self.tableView.reloadData()
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
                    self.postResults = nil
                    self.userResults = userResults
                    self.tableView.reloadData()
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
                    self.postResults = nil
                    self.userResults = userResults
                    self.tableView.reloadData()
                }
            }
        case 2: // Search topicPosts
            if language == .english {
                collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = self.db.collection("topicPosts")
            }
            
            let titleRef: Query!
            if musicTrackOnly {
                titleRef = collectionRef.whereField("musicType", isEqualTo: "track").whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            } else {
                titleRef = collectionRef.whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            }
            
            titleRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addPost(document: document, isTopicPost: true)
                    }
                    self.postResults = nil
                    self.postResults = postResults
                    self.userResults = nil
                    self.tableView.reloadData()
                }
            }
            
            
            // You have to write the whole noun
            let tagRef = collectionRef.whereField("tags", arrayContains: searchText).limit(to: 10)
            
            tagRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addPost(document: document, isTopicPost: true)
                    }
                    
                    self.postResults = nil
                    self.postResults = postResults
                    self.userResults = nil
                    self.tableView.reloadData()
                    
                    
                }
            }
        default:
            return
        }
        
        
        func addUser(document: DocumentSnapshot) {
            
            if userResults.contains(where: { $0.userID == document.documentID }) {   // Check if we got the user in on of the other queries
                return
            }
            
            AuthenticationManager.shared.generateUser(document: document) { user in
                if let user = user {
                    userResults.append(user)
                }
            }
        }
        
        func addPost(document: DocumentSnapshot, isTopicPost: Bool) {
            
            let postIsAlreadyFetched = postResults.contains { $0.documentID == document.documentID }
            if postIsAlreadyFetched {   // Check if we got the user in on of the other queries
                return
            }
            
            if let post = postHelper.addThePost(document: document, isTopicPost: isTopicPost, language: language) {
                
                postResults.append(post)
            }
        }
    }
    
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if let text = searchBar.text {
            searchTheDatabase(searchText: text, searchScope: selectedScope, musicTrackOnly: false)
        }
    }
    
}
