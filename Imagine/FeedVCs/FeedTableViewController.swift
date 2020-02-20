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


class FeedTableViewController: BaseFeedTableViewController, UISearchControllerDelegate, DismissDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var sortPostsButton: DesignableButton!
    @IBOutlet weak var viewAboveTableView: UIView!
    
    let searchTableVC = SearchTableViewController()
    
    var searchController = UISearchController()
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    var loggedIn = false    // For the barButtonItem
    
    var notificationListener: ListenerRegistration?
    var friendRequests = 0
    var newBlogPost = 0
    var newMessages = 0
    var newComments = 0
    var notifications = [Comment]() // Maybe later also likes and stuff
    var upvotes = [Comment]()
    
    let defaults = UserDefaults.standard
    
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
        
        if !self.isAppAlreadyLaunchedOnce() {
            performSegue(withIdentifier: "toIntroView", sender: nil)
        }

        if let viewControllers = self.tabBarController?.viewControllers {
            if let navVC = viewControllers[2] as? UINavigationController {
                if let newVC = navVC.topViewController as? NewPostViewController {
                    newVC.delegate = self
                }
            }
        }
    }
    
    var statusBarView: UIView?
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.hidesBarsOnSwipe = false
        
        if let view = statusBarView {
            view.removeFromSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.hidesBarsOnSwipe = true
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.setBackIndicatorImage(UIImage(systemName: "hand.point.left"), transitionMaskImage: UIImage(systemName: "hand.point.left"))
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = .systemBackground
            navBarAppearance.titleTextAttributes = [.foregroundColor: Constants.imagineColor, .font: UIFont(name: "IBMPlexSans-Medium", size: 25)!]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: Constants.imagineColor, .font: UIFont(name: "IBMPlexSans-SemiBold", size: 30)]
            navBarAppearance.shadowImage = UIImage()
            
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
                        
        } else {
            self.navigationController?.navigationBar.barTintColor = .white
        }
        
        
        // Add View for statusBar background
        if let window = UIApplication.shared.keyWindow {
            let view = UIView()

            var height:CGFloat = 40
            if #available(iOS 13.0, *) {
                height = window.windowScene?.statusBarManager?.statusBarFrame.height ?? 40
                view.backgroundColor = .systemBackground
            } else {
                height = UIApplication.shared.statusBarFrame.height
                view.backgroundColor = .white
            }
            view.frame = CGRect(x: 0, y: 0, width: window.frame.width, height: height)
            statusBarView = view
            window.addSubview(statusBarView!)
        }
        
        
        DispatchQueue.main.async {
            self.checkForLoggedInUser()
        }
        
        
        
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
            postHelper.getPostsForMainFeed(getMore: getMore, sort: self.sortBy) { (posts,initialFetch)  in
                
                print("\(posts.count) neue dazu")
                if initialFetch {   // Get the first batch of posts
                    
                    if !self.isAppAlreadyLaunchedOnce() {
                        
                    } else if self.isItTheSecondTimeTheAppLaunches() {
                        self.alert(message: "Schau dir mal an was wir aus dem Netzwerk so alles machen könnten...", title: "Hast du schon auf den blauen Owen ↑ geklickt?")
                    } else if !self.alreadyAcceptedPrivacyPolicy() {
                        self.showGDPRAlert()
                    }
                    
                    self.posts = posts
                    let post = Post()
                    post.type = .topTopicCell
                    self.posts.insert(post, at: 0)
                    
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
    
    
    func loadUser() {   // After dismissal of the logInViewController
        print("Loaded")
        self.setNotificationListener()
        self.checkForLoggedInUser()
        self.setNotifications()
    }
    
    
    
    func setNotifications() {   // Ask for persmission to send Notifications
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.registerForPushNoticications(application: UIApplication.shared)
        }
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
                                    
                                    print("Im notificationsListener: \(type)")
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
                                        case "upvote":
                                            if let postID = data["postID"] as? String, let button = data["button"] as? String, let title = data["title"] as? String {
                                                
                                                if let upvote = self.upvotes.first(where: {$0.postID == postID}) {
                                                    
                                                    self.addUpvote(comment: upvote, buttonType: button)
                                                } else {
                                                    let comment = Comment()
                            
                                                    comment.postID =  postID
                                                    comment.upvotes = Votes()
                                                    comment.title = title
                                                    
                                                    self.upvotes.append(comment)
                                                    
                                                    self.addUpvote(comment: comment, buttonType: button)
                                                    
                                                    self.newComments = self.newComments+1
                                                }
                                            }
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
                                        case "upvote":
                                            if let postID = data["postID"] as? String {
                                                print("Delete upvote out of array")
                                                
                                                let count = self.upvotes.count
                                                self.upvotes = self.upvotes.filter{$0.postID != postID}
                                                
                                                if count != self.upvotes.count {
                                                    self.newComments = self.newComments-1   
                                                }
                                            }
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
    
    func addUpvote(comment: Comment, buttonType: String) {
        if let votes = comment.upvotes {

            switch buttonType {
            case "thanks":
                votes.thanks = votes.thanks+1
            case "wow":
                votes.wow = votes.wow+1
            case "ha":
                votes.ha = votes.ha+1
            case "nice":
                votes.nice = votes.nice+1
            default:
                print("Something went wrong")
            }
        }
    }
    
    func setBarButtonProfileBadge(value: Int) {
        if value >= 1 {
            self.smallNumberForInvitationRequest.text = String(value)
            self.smallNumberForInvitationRequest.isHidden = false
        } else {
            self.smallNumberForInvitationRequest.isHidden = true
        }
    }
    
    func setBlogPostBadge(value: Int) {
        print("Das sind die BlogPosts: \(value)")
        if value >= 1 {
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
            
            if post.type == .topTopicCell {
                tableView.deselectRow(at: indexPath, animated: false)
            } else {
                performSegue(withIdentifier: "showPost", sender: post)
            }
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
        
        if segue.identifier == "toIntroView" {
            if let introVC = segue.destination as? SwipeCollectionViewController {
                introVC.diashow = .intro
            }
        }
        
        if segue.identifier == "toUserCollection" {
            if let userVC = segue.destination as? UserFeedCollectionViewController {
                if let chosenUser = sender as? User {   // Another User
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                } else { // The CurrentUser
                    userVC.currentState = .ownProfileWithEditing
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
            if let webVC = segue.destination as? WebViewController {
                if let chosenPost = sender as? Post {
                    
                    webVC.post = chosenPost
                    
                } else if let chosenLink = sender as? String {
                    webVC.link = chosenLink
                }
            }
        }
        if segue.identifier == "toUserSegue" {
            if let userVC = segue.destination as? UserFeedTableViewController {
                if let chosenUser = sender as? User {   // Another User
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                } else { // The CurrentUser
                    userVC.delegate = self
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
        if segue.identifier == "toFactSegue" {
            if let fact = sender as? Fact {
                if let factVC = segue.destination as? FactParentContainerViewController {
                        factVC.fact = fact
                        self.notifyFactCollectionViewController(fact: fact)
                }
            }
        }
        
        if segue.identifier == "goToPostsOfTopic" {
            if let fact = sender as? Fact {
                if let factVC = segue.destination as? PostsOfFactTableViewController {
                    
                    factVC.fact = fact
                    self.notifyFactCollectionViewController(fact: fact)
                    
                }
            }
        }
    }
    
    func notifyFactCollectionViewController(fact: Fact) {
        if let viewControllers = self.tabBarController?.viewControllers {
            if let navVC = viewControllers[3] as? UINavigationController {
                if let factVC = navVC.topViewController as? FactCollectionViewController {
                    factVC.registerRecentFact(fact: fact)
                }
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
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)    // Apparently needed for the rounded corners
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
            button.layer.borderWidth =  0.1
            button.layer.borderColor = Constants.imagineColor.cgColor
            
            
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

            button.layer.cornerRadius = 4
            button.addTarget(self, action: #selector(self.logInButtonTapped), for: .touchUpInside)
            button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 15)
            button.setTitle("Log-In", for: .normal)
            button.setTitleColor(Constants.imagineColor, for: .normal)

            
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
        label.isHidden = true
        
        return label
    }()
    
    
    @objc func BarButtonItemTapped() {
        sideMenu.showMenu()
        
        let notifications = self.notifications+self.upvotes
        sideMenu.checkNotifications(invitations: self.friendRequests, notifications: notifications)
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
    
    //MARK: - TopView
    
    @IBAction func sortPostsTapped(_ sender: Any) {
                
        UIView.animate(withDuration: 0.2, animations: {
            self.sortPostsButton.alpha = 0
        }) { (_) in
            self.increaseTopView()
        }
    }
    
    override func decreaseTopView() {
        
        guard let headerView = tableView.tableHeaderView else {
          return
        }
        
        let size = CGSize(width: self.view.frame.width, height: 30)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.sortingStackView.alpha = 0
        }) { (_) in
            self.sortingStackView.isHidden = true
        }
        
        if headerView.frame.size.height != size.height {
            headerView.frame.size.height = size.height
        }
        
        self.tableView.tableHeaderView = headerView
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }) { (_) in
            UIView.animate(withDuration: 0.1) {
                self.sortPostsButton.alpha = 1
            }
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
        label.isHidden = true
        
        return label
    }()
    
    func blogPostSelected(blogPost: BlogPost) {
        self.newsMenu.handleDismiss()
        
        if blogPost.isCurrentProjectsCell {
            //Go to Imagine information site
        } else {
            self.performSegue(withIdentifier: "toBlogPost", sender: blogPost)
        }
    }
    
    func donationSourceTapped(link: String) {
        performSegue(withIdentifier: "goToLink", sender: link)
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
                if let user = Auth.auth().currentUser {     //Only works if you get notifications for your own posts
                    post.originalPosterUID = user.uid
                }
                performSegue(withIdentifier: "showPost", sender: post)
            }
        case .toComment:
            if let id = id{
                let post = Post()
                post.documentID = id
                post.toComments = true
                if let user = Auth.auth().currentUser {
                    post.originalPosterUID = user.uid
                }
                performSegue(withIdentifier: "showPost", sender: post)
            }
        default:
            print("nothing happens")
        }
        
    }
    
//    //MARK: - FirstTimeOpenedAppScreen
//
//    let blackView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
////        view.alpha = 0
//
//        return view
//    }()
//
//    let introView: UIView = {
//       let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.clipsToBounds = true
//        view.layer.cornerRadius = 20
//        if #available(iOS 13.0, *) {
//            view.backgroundColor = .systemBackground
//        } else {
//            view.backgroundColor = .white
//        }
//        view.layer.borderColor = Constants.imagineColor.cgColor
//        view.layer.borderWidth = 5
//
//        return view
//    }()
//
//    let introLabel: UILabel = {
//       let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = UIFont(name: "IBMPlexSans", size: 24)
//        if #available(iOS 13.0, *) {
//            label.textColor = .label
//        } else {
//            label.textColor = .black
//        }
//        label.text = Constants.texts.introText
//        label.numberOfLines = 0
//        label.minimumScaleFactor = 0.5
//
//        return label
//    }()
//
//    let introButton: DesignableButton = {
//       let button = DesignableButton()
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setTitle("🙏", for: .normal)
//        button.layer.borderColor = Constants.imagineColor.cgColor
//        button.layer.borderWidth = 2
//        button.layer.cornerRadius = 4
//
//        return button
//    }()
//
//    @objc func dismissIntroView() {
//        blackView.removeFromSuperview()
//        introView.removeFromSuperview()
//    }
//
//    func showIntroView() {
//        if let window = UIApplication.shared.keyWindow {
//
//            window.addSubview(blackView)
//            blackView.frame = window.frame
//
//            introView.addSubview(introLabel)
//
//            introView.addSubview(introButton)
//            introButton.centerXAnchor.constraint(equalTo: introView.centerXAnchor).isActive = true
//            introButton.bottomAnchor.constraint(equalTo: introView.bottomAnchor, constant: -10).isActive = true
//            introButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
//            introButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
//
//            introLabel.leadingAnchor.constraint(equalTo: introView.leadingAnchor, constant: 10).isActive = true
//            introLabel.trailingAnchor.constraint(equalTo: introView.trailingAnchor, constant: -10).isActive = true
//            introLabel.topAnchor.constraint(equalTo: introView.topAnchor, constant: 10).isActive = true
//            introLabel.bottomAnchor.constraint(equalTo: introButton.topAnchor, constant: -30).isActive = true
//
//            window.addSubview(introView)
//            introView.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 20).isActive = true
//            introView.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20).isActive = true
////            introView.topAnchor.constraint(equalTo: window.topAnchor, constant: 50).isActive = true
//            introView.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -50).isActive = true
//
//            introButton.addTarget(self, action: #selector(dismissIntroView), for: .touchUpInside)
//        }
//    }
//
    func isAppAlreadyLaunchedOnce() -> Bool {
        
        if let _ = defaults.string(forKey: "isAppLaunchedOnce"){
            return true
        } else {
            defaults.set(true, forKey: "isAppLaunchedOnce")
            print("App launched first time")
            return false
        }
    }
    
    func alreadyAcceptedPrivacyPolicy() -> Bool {
        if let _ = defaults.string(forKey: "askedAboutCookies") {
            return true
        } else {
            return false
        }
    }
    
    func showGDPRAlert() {
        let alert = UIAlertController(title: "Wir haben 'Cookies' bei Imagine", message: "Gemäß unseren Datenschutzrichtlinien möchten wir damit herausfinden, wie die User unsere App nutzen und welche Features beliebt sind. Anonymisiert natürlich! Du kannst die Einstellung auch jederzeit ändern.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Zu den Datenschutzrichtlinien", style: .default, handler: { (_) in
            
            if let url = URL(string: "https://donmalte.github.io") {
                UIApplication.shared.open(url)
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Ich akzeptiere Cookies", style: .default, handler: { (_) in
            
            self.defaults.set(true, forKey: "acceptedCookies")
            self.defaults.set(true, forKey: "askedAboutCookies")
            Analytics.setAnalyticsCollectionEnabled(true)
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Keine Cookies", style: .cancel, handler: { (_) in
            
            //Already set to false
            self.defaults.set(false, forKey: "acceptedCookies")
            self.defaults.set(true, forKey: "askedAboutCookies")
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func isItTheSecondTimeTheAppLaunches() -> Bool {
        if let _ = defaults.string(forKey: "isItTheSecondTimeTheAppLaunches") {
            return false
        } else {
            defaults.set(true, forKey: "isItTheSecondTimeTheAppLaunches")
            print("App launched second time")
            return true
        }
    }
}


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
            let titleRef = db.collection("Posts").whereField("title", isGreaterThan: searchText).whereField("title", isLessThan: "\(searchText)ü").limit(to: 10)
            
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
            let fullNameRef = db.collection("Users").whereField("full_name", isGreaterThan: searchText).whereField("full_name", isLessThan: "\(searchText)ü").limit(to: 3)
            
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
            
            let nameRef = db.collection("Users").whereField("name", isGreaterThan: searchText).whereField("name", isLessThan: "\(searchText)ü").limit(to: 3)
            
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
            
            let surnameRef = db.collection("Users").whereField("surname", isGreaterThan: searchText).whereField("surname", isLessThan: "\(searchText)ü").limit(to: 3)
            
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
                
                if let name = docData["name"] as? String, let surname = docData["surname"] as? String {
                    
                    //When you search for names, you can search for their real names and it will answer, but the names will not show up...?!
                    
                    let name = name
//                    let surname = surname
                    user.displayName = name
                    user.userUID = document.documentID
                    if let imageURL = docData["profilePictureURL"] as? String {
                        user.imageURL = imageURL
                    }
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
                    post.mediaWidth = CGFloat(imageWidth ?? 0)
                    post.mediaHeight = CGFloat(imageHeight ?? 0)
                    post.documentID = document.documentID
                    post.originalPosterUID = op
                    
                    postResults.append(post)
                    
                }
            }
        }
    }
}

extension FeedTableViewController: LogOutDelegate {
    func deleteListener() {     // Triggered when the User logges themselve out. Otherwise they would get notified after they logged themself in and a new user could not get a new notificationListener
        self.notificationListener?.remove()
        self.notificationListener = nil
        
        self.newComments = 0
        self.friendRequests = 0
        self.newBlogPost = 0
        self.newMessages = 0
        self.notifications.removeAll()
        
        print("listener removed")
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

extension FeedTableViewController: JustPostedDelegate {
    func posted() {
        self.getPosts(getMore: false)
    }
}


