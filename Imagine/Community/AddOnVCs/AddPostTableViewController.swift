//
//  AddPostTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

protocol AddItemDelegate: class {
    func itemAdded()
}

enum SelectedPostType {
    case post
    case topicPost
    case saved
}

class AddPostTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var lastPostLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var headerDescriptionLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var selectedPostType: SelectedPostType = .post
    var playlistTracksOnly = false
    
    var posts = [Post]()
    var topicPosts = [Post]()
    var savedPosts = [Post]()
    
    let db = FirestoreRequest.shared.db
    let postHelper = PostHelper.shared
    
    var addOn: AddOn? {
        didSet {
            if let addOn = addOn {
                addOn.delegate = self
            }
        }
    }
        
    weak var addItemDelegate: AddItemDelegate?
    
    var selectedPost: Post? {
        didSet {
            self.increaseHeaderView(post: selectedPost!)
        }
    }
    
    let searchCellIdentifier = "SearchPostCell"
    
    let searchTableVC = SearchTableViewController()
    var searchController = UISearchController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapTapped))
        tap.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(tap)
        
        doneButton.isEnabled = false
        doneButton.tintColor = UIColor.imagineColor.withAlphaComponent(0.5)
        
        getPosts()
        setUpSearchController()
        extendedLayoutIncludesOpaqueBars = true
        
        headerTextField.delegate = self
        
        tableView.register(SearchPostCell.self, forCellReuseIdentifier: searchCellIdentifier)
    }
    
    @objc func dismissTapTapped() {
        self.headerTextField.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.hidesSearchBarWhenScrolling = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    func getPosts() {
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .en {
            collectionRef = self.db.collection("Data").document("en").collection("posts")
        } else {
            collectionRef = self.db.collection("Posts")
        }
        let ref: Query!
        if playlistTracksOnly {
            ref = collectionRef.whereField("musicType", isEqualTo: "track").order(by: "createTime", descending: true).limit(to: 15)
        } else {
            ref = collectionRef.order(by: "createTime", descending: true).limit(to: 15)
        }
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                                                
                        if let post = self.postHelper.addThePost(document: document, isTopicPost: false, language: language) {
                            self.posts.append(post)
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func getTopicPosts() {
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .en {
            collectionRef = self.db.collection("Data").document("en").collection("topicPosts")
        } else {
            collectionRef = self.db.collection("TopicPosts")
        }
        
        let ref: Query!
        if playlistTracksOnly {
            ref = collectionRef.whereField("musicType", isEqualTo: "track").order(by: "createTime", descending: true).limit(to: 15)
        } else {
            ref = collectionRef.order(by: "createTime", descending: true).limit(to: 15)
        }
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                                                
                        if let post = self.postHelper.addThePost(document: document, isTopicPost: true, language: language) {
                            self.topicPosts.append(post)
                        }
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func setUpSearchController() {
        
        // I think it is unnecessary to set the searchResultsUpdater and searchcontroller Delegate here, but I couldnt work out an alone standing SearchViewController
        
        searchTableVC.customDelegate = self
        
        searchController = UISearchController(searchResultsController: searchTableVC)
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = NSLocalizedString("search_placeholder", comment: "")
        searchController.searchBar.scopeButtonTitles = ["Posts", "TopicPosts"]
        searchController.delegate = self
        searchController.searchBar.delegate = self
        
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.searchController.isActive = false
        definesPresentationContext = true
    }
    
    func showSelectedPost(post: Post) {
        
        guard let headerView = tableView.tableHeaderView else {
            return
        }
        
        headerPostView.addSubview(headerTitleLabel)
        headerTitleLabel.topAnchor.constraint(equalTo: headerPostView.topAnchor, constant: 5).isActive = true
        headerTitleLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        headerTitleLabel.leadingAnchor.constraint(equalTo: headerPostView.leadingAnchor, constant: 5).isActive = true
        headerTitleLabel.trailingAnchor.constraint(equalTo: headerPostView.trailingAnchor, constant: -5).isActive = true
        
        headerPostView.addSubview(headerImageView)
        headerImageView.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 5).isActive = true
        headerImageView.bottomAnchor.constraint(equalTo: headerPostView.bottomAnchor, constant: -5).isActive = true
        headerImageView.leadingAnchor.constraint(equalTo: headerPostView.leadingAnchor, constant: 5).isActive = true
        headerImageView.trailingAnchor.constraint(equalTo: headerPostView.trailingAnchor, constant: -5).isActive = true
        
        headerView.addSubview(headerTextField)
        headerTextField.heightAnchor.constraint(equalToConstant: 34).isActive = true
        headerTextField.bottomAnchor.constraint(equalTo: lastPostLabel.topAnchor, constant: -15).isActive = true
        headerTextField.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
        headerTextField.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10).isActive = true
        
        
        headerView.addSubview(headerPostView)
        headerPostView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 15).isActive = true
        headerPostView.bottomAnchor.constraint(equalTo: headerTextField.topAnchor, constant: -5).isActive = true
        headerPostView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 50).isActive = true
        headerPostView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -50).isActive = true
        
        profileView.addSubview(profileImageView)
        profileImageView.topAnchor.constraint(equalTo: profileView.topAnchor, constant: 3).isActive = true
        profileImageView.leadingAnchor.constraint(equalTo: profileView.leadingAnchor, constant: 3).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        profileView.addSubview(profileNameLabel)
        profileNameLabel.topAnchor.constraint(equalTo: profileView.topAnchor, constant: 3).isActive = true
        profileNameLabel.bottomAnchor.constraint(equalTo: profileView.bottomAnchor, constant: -3).isActive = true
        profileNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 5).isActive = true
        profileNameLabel.trailingAnchor.constraint(equalTo: profileView.trailingAnchor, constant: -5).isActive = true
        
        headerView.addSubview(headerButton)
        headerButton.topAnchor.constraint(equalTo: headerPostView.topAnchor).isActive = true
        headerButton.bottomAnchor.constraint(equalTo: headerPostView.bottomAnchor).isActive = true
        headerButton.leadingAnchor.constraint(equalTo: headerPostView.leadingAnchor).isActive = true
        headerButton.trailingAnchor.constraint(equalTo: headerPostView.trailingAnchor).isActive = true
        
        if let user = post.user {
            headerImageView.addSubview(profileView)
            profileView.bottomAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: -5).isActive = true
            profileView.leadingAnchor.constraint(equalTo: headerImageView.leadingAnchor, constant: 5).isActive = true
            profileView.trailingAnchor.constraint(equalTo: profileNameLabel.trailingAnchor, constant: 5).isActive = true
            profileView.heightAnchor.constraint(equalToConstant: 26).isActive = true
                        
            if let urlString = user.imageURL, let url = URL(string: urlString) {
                profileImageView.sd_setImage(with: url, completed: nil)
            } else {
                profileImageView.image = UIImage(named: "default-user")
            }
            
            profileNameLabel.text = user.displayName
        } else {
            profileNameLabel.text = ""
            profileImageView.image = nil
        }
        
        headerView.layoutIfNeeded()
        
        if post.type == .multiPicture, let imageURL = post.images?.first?.url, let url = URL(string: imageURL) {
                headerImageView.sd_setImage(with: url, completed: nil)
        } else if post.type == .picture, let link = post.image?.url, let url = URL(string: link) {
            headerImageView.sd_setImage(with: url, completed: nil)
        } else if post.type == .GIF {
            headerImageView.image = UIImage(named: "GIFIcon")
        } else if post.type == .link {
            if let music = post.music, let url = URL(string: music.musicImageURL) {
                headerImageView.sd_setImage(with: url, completed: nil)
            } else if let link = post.link, let imageURL = link.imageURL, let url = URL(string: imageURL) {
                headerImageView.sd_setImage(with: url, completed: nil)
            }
        } else {
            headerImageView.image = UIImage(named: "savePostImage")
        }
        
        headerTitleLabel.text = post.title
        
        doneButton.isEnabled = true
        doneButton.tintColor = UIColor.imagineColor.withAlphaComponent(1)
        
    }
    
    
    
    func increaseHeaderView(post: Post) {    // For sorting purpose
        
        guard let headerView = tableView.tableHeaderView else {
          return
        }
        
        let size = CGSize(width: self.view.frame.width, height: 400)
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
        }
        self.tableView.tableHeaderView = headerView
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.headerDescriptionLabel.alpha = 0
        }) { (_) in
            
            UIView.animate(withDuration: 0.3) {
                self.headerDescriptionLabel.isHidden = true
                self.showSelectedPost(post: post)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch selectedPostType {
        case .post:
            return posts.count
        case .topicPost:
            return topicPosts.count
        case .saved:
            return savedPosts.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post: Post!
        switch selectedPostType {
        case .post:
            post = posts[indexPath.row]
        case .topicPost:
            post = topicPosts[indexPath.row]
        case .saved:
            post = savedPosts[indexPath.row]
        }
        
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: searchCellIdentifier, for: indexPath) as? SearchPostCell {
            
            cell.post = post
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post: Post
        switch selectedPostType {
        case .post:
            post = posts[indexPath.row]
        case .topicPost:
            post = topicPosts[indexPath.row]
        case .saved:
            post = savedPosts[indexPath.row]
        }
        
        self.selectedPost = post
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPostSegue" {
            if let vc = segue.destination as? PostViewController {
                if let post = sender as? Post {
                    vc.post = post
                }
            }
        }
    }
    
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            selectedPostType = .post
            tableView.reloadData()
        case 1:
            selectedPostType = .topicPost
            if topicPosts.count == 0 {
                self.getTopicPosts()
            } else {
                tableView.reloadData()
            }
        case 2:
            selectedPostType = .saved
            tableView.reloadData()
        default:
            selectedPostType = .post
            tableView.reloadData()
        }
    }
    
    //MARK:- SaveInstance
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let post = self.selectedPost, let addOn = addOn {
            if headerTextField.text != "" {
                post.addOnTitle = headerTextField.text!
            }
            
            addOn.saveItem(item: post)
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        headerTextField.resignFirstResponder()
    }
    
    
    func checkIfFirstEntry(collectionReferenceString: String, fact: Community, gotCollection: @escaping (Bool) -> Void) {
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(fact.documentID).collection(collectionReferenceString)
        
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    
                    if snap.isEmpty {
                        print("No document in snap")
                        gotCollection(false)
                    } else {
                        print("Got Documents in snap")
                        gotCollection(true)
                    }
                }
            }
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    //MARK:- UI SetUp
    
    let headerPostView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        
        return view
    }()
    
    let headerImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemBackground
        
        return imageView
    }()
    
    let headerTitleLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 16)
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.6
        
        return label
    }()
    
    let headerTextField: UITextField = {
       let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = NSLocalizedString("optional_explanation_placeholder", comment: "")
        textField.font = UIFont(name: "IBMPlexSans", size: 15)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        
        return textField
    }()
    
    let profileView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        
        return view
    }()
    
    let profileImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        
        return imageView
    }()
    
    let profileNameLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.6
        
        return label
    }()
    
    let headerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toPostButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    @objc func toPostButtonTapped() {
        if let post = selectedPost {
            performSegue(withIdentifier: "toPostSegue", sender: post)
        }
    }
    
}

//MARK:- OptionalInformationDelegate
extension AddPostTableViewController: AddOnDelegate {
    func fetchCompleted() {
        print("not needed")
    }
    
    func itemAdded(successfull: Bool) {
        if successfull {
            let alert = UIAlertController(title: NSLocalizedString("done", comment: "done"), message: NSLocalizedString("addOn_creation_successfull", comment: "done and successfull"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
                self.addItemDelegate?.itemAdded()
                self.navigationController?.popViewController(animated: true)
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Something went wrong", message: "Please try later again or ask the developers to do a better job. We are sorry!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true)
        }
    }
}


//MARK:- SearchController
extension AddPostTableViewController: UISearchResultsUpdating, UISearchBarDelegate, CustomSearchViewControllerDelegate, UISearchControllerDelegate {
    
    func didSelectItem(item: Any) {
        if let post = item as? Post {
            searchController.dismiss(animated: true) {
                self.selectedPost = post
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        searchController.searchResultsController?.view.isHidden = false
        
        let searchBar = searchController.searchBar
        var scope = searchBar.selectedScopeButtonIndex
        if scope == 1 {  // to ease the switch in the searchTableVC.searchTheDatabase function
            scope = 2
        }
        
        if searchBar.text! != "" {
            searchTableVC.searchTheDatabase(searchText: searchBar.text!, searchScope: scope, musicTrackOnly: playlistTracksOnly)
        } else {
            // Clear the searchTableView
            searchTableVC.showBlankTableView()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        var scope = searchBar.selectedScopeButtonIndex
        if scope == 1 {  // to ease the switch in the searchTableVC.searchTheDatabase function
            scope = 2
        }
        
        if let text = searchBar.text {
            if text != "" {
                searchTableVC.searchTheDatabase(searchText: text, searchScope: scope, musicTrackOnly: playlistTracksOnly)
            } else {
                searchTableVC.showBlankTableView()
            }
        }
    }
}
