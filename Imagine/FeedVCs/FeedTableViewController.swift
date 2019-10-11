//
//  FeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SDWebImage
import Reachability
import EasyTipView

class FeedTableViewController: BaseFeedTableViewController, UISearchControllerDelegate, DismissDelegate {
    
    let searchTableVC = SearchTableViewController()
    
    var searchController = UISearchController()
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
//    private var invitationCount = 0
    var loggedIn = false    // For the barButtonItem
    
    var notificationListener: ListenerRegistration?
    var friendRequests = 0
    var newBlogPost = 0
    var newMessages = 0
    var newComments = 0
    var notifications = [Comment]() // Maybe later also likes and stuff
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpSearchController()
        setUpEasyTipViewPreferences()
        
        // Initiliaze ScreenEdgePanRecognizer
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self,
                                                                action: #selector(BarButtonItemTapped))
        screenEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenEdgeRecognizer)
        
        // Others
        loadBarButtonItem()
        
        setNotificationListener()
        
        getPosts(getMore: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        DispatchQueue.main.async {
            self.checkForLoggedInUser()
        }
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = .white
        
        //        // Restore the searchController's active state.
        //        if restoredState.wasActive {
        //            searchController.isActive = restoredState.wasActive
        //            restoredState.wasActive = false
        //
        //            if restoredState.wasFirstResponder {
        //                searchController.searchBar.becomeFirstResponder()
        //                restoredState.wasFirstResponder = false
        //            }
        //        } Aus dem apple tutorial für die suche
    }
    
    
    override func didReceiveMemoryWarning() {
        print("Memory Pressure triggered")
        SDImageCache.shared.clearMemory()
        
    }
    
    // MARK: - Methods
    
    @objc override func getPosts(getMore:Bool) {
        /*
         If "getMore" is true, you want to get more Posts, or the initial batch of 20 Posts, if not you want to refresh the current feed
         */
        print("Get Posts")
        
        if isConnected() {
        
            self.view.activityStartAnimating()
            postHelper.getPostsForMainFeed(getMore: getMore) { (posts,initialFetch)  in
                
                print("\(posts.count) neue dazu")
                if initialFetch {   // Get the first batch of posts
                    self.posts = posts
                    self.tableView.reloadData()
                    self.fetchesPosts = false
                    
//                    self.postHelper.getEvent(completion: { (post) in
//                        self.posts.insert(post, at: 8)
//                        self.tableView.reloadData()
//                    })
                    
                    // remove ActivityIndicator incl. backgroundView
                    self.view.activityStopAnimating()
                    
                    self.refreshControl?.endRefreshing()
                } else {    // Append the next batch to the existing
                    var indexes : [IndexPath] = [IndexPath]()
                    
                    for result in posts {
                        let row = self.posts.count
                        
                        indexes.append(IndexPath(row: row, section: 0))
                        self.posts.append(result)
                    }
                    
                    if #available(iOS 11.0, *) {
                        self.tableView.performBatchUpdates({
                            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                            self.tableView.insertRows(at: indexes, with: .bottom)
                        }, completion: { (_) in
                            self.fetchesPosts = false
                        })
                    } else {
                        // Fallback on earlier versions
                        self.tableView.beginUpdates()
                        self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                        self.tableView.insertRows(at: indexes, with: .right)
                        self.tableView.endUpdates()
                        
                        self.fetchesPosts = false
                    }
                    
                    self.view.activityStopAnimating()
                    print("Jetzt haben wir \(self.posts.count)")
                }
            }
        } else {
            fetchRequested = true
        }
    }
    
    
    // After dismissal of the logInViewController
    func loadUser() {
        print("Loaded")
        self.checkForLoggedInUser()
    }
    
    
    
    func checkForLoggedInUser() {
        print("check")
        if let _ = Auth.auth().currentUser {
            //Still logged in
            self.loadBarButtonItem()
            self.screenEdgeRecognizer.isEnabled = true
        } else {
            if let items = self.tabBarController?.tabBar.items {
                let tabItem = items[1]
                tabItem.badgeValue = nil
            }
            self.screenEdgeRecognizer.isEnabled = false
            self.loadBarButtonItem()
            
            if let listener = self.notificationListener {
                listener.remove()
            }
        }
    }
    
    func setNotificationListener() {
        
        if let _ = notificationListener {
            print("Listener already Set")
        } else {
            print("Set listener")
            if let user = Auth.auth().currentUser {
                let notRef = db.collection("Users").document(user.uid).collection("notifications")
                
                notificationListener = notRef.addSnapshotListener { (snap, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        
                        if let snapshot = snap {
                            snapshot.documentChanges.forEach { (change) in
                                let data = change.document.data()
                                if let type = data["type"] as? String {
                                    
                                    switch change.type {
                                        
                                    case .added:
                                        
                                        switch type {
                                        case "friend":
                                            
                                            self.friendRequests = self.friendRequests+1
                                        case "comment":
                                            if let text = data["comment"] as? String, let author = data["name"] as? String, let postID = data["postID"] as? String {
                                                let comment = Comment()
                                                comment.postID = change.document.documentID
                                                comment.author = author
                                                comment.postID = postID
                                                comment.text = text
                                                self.notifications.append(comment)
                                            }
                                            self.newComments = self.newComments+1
                                        case "message":
                                            self.newMessages = self.newMessages+1
                                        case "blogPost":
                                            self.newBlogPost = self.newBlogPost+1
                                        default:
                                            print("Unknown Type")
                                        }
                                        
                                    case .removed:
                                        print("Something got removed")
                                        switch type {
                                        case "friend":
                                            self.friendRequests = self.friendRequests-1
                                        case "comment":
                                            self.newComments = self.newComments-1
                                            if let postID = data["postID"] as? String {
                                                print("Delete notification out of array")
                                                self.notifications = self.notifications.filter{$0.postID != postID}
                                            }
                                        
                                        case "message":
                                            self.newMessages = self.newMessages-1
                                        case "blogPost":
                                            self.newBlogPost = self.newBlogPost-1
                                        default:
                                            print("Unknown Type")
                                        }
                                        
                                    default:
                                        print("These cant get modifier")
                                    }
                                    
                                }
                            }
                            self.setBarButtonProfileBadge(value: self.newComments+self.friendRequests)
                            self.setBlogPostBadge(value: self.newBlogPost)
                            self.setChatBadge(value: self.newMessages)
                        }
                    }
                }
            }
        }
    }
    
    func setBarButtonProfileBadge(value: Int) {
        if value != 0 {
            self.smallNumberForInvitationRequest.text = String(value)
            self.smallNumberForInvitationRequest.isHidden = false
        } else {
            self.smallNumberForInvitationRequest.isHidden = true
        }
    }
    
    func setBlogPostBadge(value: Int) {
        if value != 0 {
            self.smallNumberForImagineBlogButton.text = String(value)
            self.smallNumberForImagineBlogButton.isHidden = false
        } else {
            self.smallNumberForImagineBlogButton.isHidden = true
        }
    }
    
    func setChatBadge(value: Int) {
        if let tabItems = tabBarController?.tabBar.items {
            let tabItem = tabItems[1] //Chats
            if value != 0 {
                tabItem.badgeValue = String(value)
            } else {
                tabItem.badgeValue = nil
            }
        }
    }

    
    // MARK: - TableViewStuff
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var post = Post()
        var user = User()

        // Check to see which table view cell was selected.
        if tableView === self.tableView {
            post = posts[indexPath.row]
            
            performSegue(withIdentifier: "showPost", sender: post)
        } else {
            if let searchVC = self.searchController.searchResultsController as? SearchTableViewController {
                
                if let postResults = searchVC.postResults {
                    post = postResults[indexPath.row]
                    performSegue(withIdentifier: "showPost", sender: post)

                } else if let userResult = searchVC.userResults {
                    user = userResult[indexPath.row]
                    performSegue(withIdentifier: "toUserSegue", sender: user)
                }
                
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                }
            }
        }
        
        if segue.identifier == "toUserCollection" {
            if let userVC = segue.destination as? UserFeedCollectionViewController {
                if let chosenUser = sender as? User {   // Another User
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                } else { // The CurrentUser
                    userVC.currentState = .ownProfileWithEditing
                    print("Hier wird der currentstate eingestellt")
                }
            }
        }
        if segue.identifier == "meldenSegue" {
            if let chosenPost = sender as? Post {
                if let reportVC = segue.destination as? MeldenViewController {
                    reportVC.post = chosenPost
                    
                }
            }
        }
        if segue.identifier == "goToLink" {
            if let chosenPost = sender as? Post {
                if let webVC = segue.destination as? WebViewController {
                    webVC.post = chosenPost
                    
                }
            }
        }
        if segue.identifier == "toUserSegue" {
            if let userVC = segue.destination as? UserFeedTableViewController {
                if let chosenUser = sender as? User {   // Another User
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                } else { // The CurrentUser
                    userVC.currentState = .ownProfileWithEditing
                    print("Hier wird der currentstate eingestellt")
                }
            }
        }
        if segue.identifier == "toBlogPost" {
            if let chosenPost = sender as? BlogPost {
                if let blogVC = segue.destination as? BlogPostViewController {
                    blogVC.blogPost = chosenPost
                }
            }
        }
        if segue.identifier == "toLogInSegue" {
            if let vc = segue.destination as? LogInViewController {
                vc.delegate = self
            }
        }
    }
    
    // MARK: - SearchBar
    
    func setUpSearchController() {
        searchTableVC.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: searchTableVC)
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Durchsuche Imagine"
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.scopeButtonTitles = ["Posts", "User"]
        searchController.searchBar.delegate = self
        
        if #available(iOS 11.0, *) {
            // For iOS 11 and later, place the search bar in the navigation bar.
            self.navigationItem.searchController = searchController
        } else {
            // For iOS 10 and earlier, place the search controller's search bar in the table view's header.
            tableView.tableHeaderView = searchController.searchBar
        }
        self.navigationItem.hidesSearchBarWhenScrolling = true
        self.searchController.isActive = false
        definesPresentationContext = true
    }
    
    @objc func searchBarTapped() {
        // Show search bar
        self.fetchesPosts = true // Otherwise the view thinks it scrolled to the button via the function scrollViewDidScroll in BaseFeedTableViewController, couldn't figure a better way

        //        self.searchController.isActive = true   // Not perfekt but works
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.fetchesPosts = true // Otherwise the view thinks it scrolled to the button via the function scrollViewDidScroll in BaseFeedTableViewController, could figure a better way
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        self.fetchesPosts = false   // Otherwise the view thinks it scrolled to the button via the function scrollViewDidScroll in BaseFeedTableViewController, could figure a better way
    }
    
    
    // MARK: - Navigation Items
    
    func loadBarButtonItem() {
        
        if self.navigationItem.rightBarButtonItems == nil {
            self.createRightBarButtons()
        }
        
        if isConnected() {
            
            // needs Internet to check if User is logged in and/or profilePicture
            
            if self.navigationItem.leftBarButtonItem == nil {
                
                self.createBarButton()
                
                self.setNotificationListener()
            } else {    // Already got barButtons
                
                if let _ = Auth.auth().currentUser {
                    if self.loggedIn == false { // Logged in but no profileButton
                        self.createBarButton()
                    }
                } else {
                    if self.loggedIn {
                        self.createBarButton()  // Not logged in but still proileButton
                    }
                }
            }
        }
    }
    
    func createRightBarButtons() {
        // Set Blog and Search Button
        let imagineButton = DesignableButton(type: .custom)
        imagineButton.setImage(UIImage(named: "ImagineSign"), for: .normal)
        imagineButton.addTarget(self, action: #selector(self.imagineSignTapped), for: .touchUpInside)
        imagineButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        imagineButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        imagineButton.addSubview(self.smallNumberForImagineBlogButton)
        
        
        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(self.searchBarTapped))
        let imagineBarButton = UIBarButtonItem(customView: imagineButton)
        self.navigationItem.rightBarButtonItems = [searchBarButton, imagineBarButton]
    }
    
    func createBarButton() {
        // View so I there can be a small number for Invitations
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 35).isActive = true
        view.widthAnchor.constraint(equalToConstant: 35).isActive = true
        
        //create new Button for the profilePictureButton
        let button = DesignableButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        // Wenn jemand eingeloggt ist:
        if let user = Auth.auth().currentUser {
            self.loggedIn = true
            
            button.widthAnchor.constraint(equalToConstant: 35).isActive = true
            button.heightAnchor.constraint(equalToConstant: 35).isActive = true
            button.imageView?.contentMode = .scaleAspectFill
            button.layer.cornerRadius = button.frame.width/2
            button.addTarget(self, action: #selector(self.BarButtonItemTapped), for: .touchUpInside)
            button.addTarget(self, action: #selector(self.BarButtonItemTapped), for: .touchUpInside)
            button.layer.borderWidth =  0.1
            button.layer.borderColor = UIColor.black.cgColor
            
            if let url = user.photoURL{ // Set Photo
                
                do {
                    let data = try Data(contentsOf: url)
                    
                    if let image = UIImage(data: data) {
                        
                        //set image for button
                        button.setImage(image, for: .normal)
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
            } else {    // If no profile picture is set
                button.setImage(UIImage(named: "default-user"), for: .normal)
            }
            
            view.addSubview(button)
            view.addSubview(self.smallNumberForInvitationRequest)
            
        } else {    // Wenn niemand eingeloggt
            self.loggedIn = false
            
            self.smallNumberForInvitationRequest.isHidden = true
            
            button.widthAnchor.constraint(equalToConstant: 50).isActive = true
            button.heightAnchor.constraint(equalToConstant: 35).isActive = true
            button.layer.cornerRadius = 5
            
            button.addTarget(self, action: #selector(self.logInButtonTapped), for: .touchUpInside)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            button.setTitle("Log-In", for: .normal)
            button.setTitleColor(.blue, for: .normal)
            //                self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            view.addSubview(button)
        }
        
        let barButton = UIBarButtonItem(customView: view)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    
    
    let smallNumberForInvitationRequest: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 25, y: 0, width: 14, height: 14))
        label.backgroundColor = .red
        label.clipsToBounds = true
        label.layer.cornerRadius = 7
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        
        return label
    }()
    
    
    @objc func BarButtonItemTapped() {
        sideMenu.showMenu()
        sideMenu.checkNotifications(invitations: self.friendRequests, notifications: self.notifications)
    }
    
    @objc func logInButtonTapped() {
        performSegue(withIdentifier: "toLogInSegue", sender: nil)
    }
    
    override func userTapped(post: Post) {
        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
    
    // MARK: - EasyTipViewPreferences
    func setUpEasyTipViewPreferences() {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "IBMPlexSans", size: 18)!
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = Constants.imagineColor
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
        preferences.drawing.textAlignment = .left
        preferences.positioning.bubbleHInset = 10
        preferences.positioning.bubbleVInset = 10
        preferences.positioning.maxWidth = self.view.frame.width-40
        // Maximum of 800 Words
        
        EasyTipView.globalPreferences = preferences
    }
    
    // MARK: - Reachability
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("Observer activated")
        addReachabilityObserver()
    }
    
    deinit {
        removeReachabilityObserver()
    }
    
    override func reachabilityChanged(_ isReachable: Bool) {
        print("changed! Connection reachable: ", isReachable, "fetch requested: ", fetchRequested)
        
        if isReachable {
            if fetchRequested { // To automatically redo the requested task
                self.getPosts(getMore: true)
            }
            
            if self.navigationItem.leftBarButtonItem == nil {
                self.loadBarButtonItem()
            }
            
            self.view.removeNoConncectionView()
        } else {
            self.view.showNoInternetConnectionView()
            // Tell User no Connection
        }
    }
    
    // MARK: - ImagineBlogButton
    
    lazy var newsMenu: NewsOverviewMenu = {
        let nM = NewsOverviewMenu()
        nM.feedTableVC = self
        return nM
    }()
    
    @objc func imagineSignTapped() {
        
        let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        
        self.newsMenu.showView(navBarHeight: navigationBarHeight)
        
        handyHelper.deleteNotifications(type: .blogPost, id: "blogPost")
    }
    
    let smallNumberForImagineBlogButton: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 20, y: 0, width: 12, height: 12))
        label.backgroundColor = .red
        label.clipsToBounds = true
        label.layer.cornerRadius = 6
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        label.text = String(1)
        
        return label
    }()
    
    func blogPostSelected(blogPost: BlogPost) {
        self.newsMenu.handleDismiss()
        
        self.performSegue(withIdentifier: "toBlogPost", sender: blogPost)
    }
    
    // MARK: - Side Menu
    
    lazy var sideMenu: SideMenu = {
        let sideMenu = SideMenu()
        sideMenu.FeedTableView = self
        return sideMenu
    }()
    
    
    
    func sideMenuButtonTapped(whichButton: SideMenuButton, id: String?) {
        
        switch whichButton {
        case .toUser:
            self.performSegue(withIdentifier: "toUserSegue", sender: nil)
        //            self.performSegue(withIdentifier: "toUserCollection", sender: nil)    // For test Zwecke
        case .toFriends:
            performSegue(withIdentifier: "toFriendsSegue", sender: nil)
        case .toSavedPosts:
            performSegue(withIdentifier: "toSavedPosts", sender: nil)
        case .toEULA:
            performSegue(withIdentifier: "toEULASegue", sender: nil)
        case .toPost:
            if let id = id{
                let post = Post()
                post.documentID = id
                post.toComments = true
                performSegue(withIdentifier: "showPost", sender: post)
            }
        default:
            print("nothing happens")
        }
        
    }
}

// Maybe load whole cells?
//extension FeedTableViewController: UITableViewDataSourcePrefetching {
//    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
//        for indexPath in indexPaths {
//            let post = posts[indexPath.row]
//
//            if let _ = imageCache.object(forKey: post.imageURL as NSString) {
//                print("Wurde schon gecached")
//            } else {
//                if let url = URL(string: post.imageURL) {
//                    print("Prefetchen neues Bild: \(post.title)")
//                    DispatchQueue.global().async {
//                        let data = try? Data(contentsOf: url)
//
//                        DispatchQueue.main.async {
//                            if let data = data {
//                                if let image = UIImage(data: data) {
//                                    self.imageCache.setObject(image, forKey: post.imageURL as NSString)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}


// MARK: - UISearchResultsUpdating Delegate
extension FeedTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        searchController.searchResultsController?.view.isHidden = false
        
        let searchBar = searchController.searchBar
        let scope = searchBar.selectedScopeButtonIndex
        
        if searchBar.text! != "" {
            searchTheDatabase(searchText: searchBar.text!, searchScope: scope)
        } else {
            // Clear the searchTableView
            if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                resultsController.postResults = nil
                resultsController.userResults = nil
                resultsController.tableView.reloadData()
            }
        }
    }
    
    func searchTheDatabase(searchText: String, searchScope: Int) {
        var postResults = [Post]()
        var userResults = [User]()
        
        switch searchScope {
        case 0: // Search Posts
            let titleRef = db.collection("Posts").whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)z").limit(to: 10)
            
            titleRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addPost(document: document)
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.postResults = nil
                        resultsController.postResults = postResults
                        resultsController.userResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            // You have to write the whole noun
            let tagRef = db.collection("Posts").whereField("tags", arrayContains: searchText).limit(to: 10)
            
            tagRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for titles: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addPost(document: document)
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.postResults = nil
                        resultsController.postResults = postResults
                        resultsController.userResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            
        case 1: // Search Users
            let fullNameRef = db.collection("Users").whereField("full_name", isGreaterThan: searchText).whereField("full_name", isLessThan: "\(searchText)z").limit(to: 3)
            
            fullNameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        addUser(document: document)
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.userResults = userResults
                        resultsController.postResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            let nameRef = db.collection("Users").whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)z").limit(to: 3)
            
            nameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addUser(document: document)
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.userResults = userResults
                        resultsController.postResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
            
            let surnameRef = db.collection("Users").whereField("surname", isGreaterThan: searchText).whereField("surname", isLessThan: "\(searchText)z").limit(to: 3)
            
            surnameRef.getDocuments { (querySnap, error) in
                if let err = error {
                    print("We have an error searching for Users: \(err.localizedDescription)")
                } else {
                    for document in querySnap!.documents {
                        
                        addUser(document: document)
                    }
                    if let resultsController = self.searchController.searchResultsController as? SearchTableViewController {
                        resultsController.userResults = userResults
                        resultsController.postResults = nil
                        
                        resultsController.tableView.reloadData()
                    }
                }
            }
        default:
            return
        }
        
        
        func addUser(document: DocumentSnapshot) {
            
            let userIsAlreadyFetched = userResults.contains { $0.userUID == document.documentID }
            if userIsAlreadyFetched {   // Check if we got the user in on of the other queries
                return
            }
            
            let user = User()
            if let docData = document.data() {
                
                if let name = docData["name"] as? String, let surname = docData["surname"] as? String, let imageURL = docData["profilePictureURL"] as? String {
                    user.name = name
                    user.surname = surname
                    user.userUID = document.documentID
                    user.imageURL = imageURL
                    if let status = docData["statusText"] as? String {
                        user.statusQuote = status
                    }
                    user.blocked = docData["blocked"] as? [String] ?? nil
                    
                    userResults.append(user)
                }
            }
        }
        
        func addPost(document: DocumentSnapshot) {
            
            let postIsAlreadyFetched = postResults.contains { $0.documentID == document.documentID }
            if postIsAlreadyFetched {   // Check if we got the user in on of the other queries
                return
            }
            let post = Post()
            if let docData = document.data() {
                
                if let title = docData["title"] as? String, let type = docData["type"] as? String, let op = docData["originalPoster"] as? String {
                    let imageURL = docData["imageURL"] as? String
                    let imageHeight = docData["imageHeight"] as? Double
                    let imageWidth = docData["imageWidth"] as? Double
                    post.title = title
                    post.documentID = document.documentID
                    post.imageURL = imageURL ?? ""
                    if let postType = self.handyHelper.setPostType(fetchedString: type) {
                        post.type = postType
                    }
                    post.imageWidth = CGFloat(imageWidth ?? 0)
                    post.imageHeight = CGFloat(imageHeight ?? 0)
                    post.documentID = document.documentID
                    post.originalPosterUID = op
                    
                    postResults.append(post)
                    
                }
            }
        }
    }


    
}

 // MARK: - UISearchBar Delegate
extension FeedTableViewController: UISearchBarDelegate {
   
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if let text = searchBar.text {
            searchTheDatabase(searchText: text, searchScope: selectedScope)
        }
    }
}
