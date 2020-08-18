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


class FeedTableViewController: BaseFeedTableViewController, DismissDelegate, UNUserNotificationCenterDelegate {
    
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
        
//        setUpSearchController()
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
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = .systemBackground
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.imagineColor, .font: UIFont(name: "IBMPlexSans-Medium", size: 25)!]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.imagineColor, .font: UIFont(name: "IBMPlexSans-SemiBold", size: 30)]
            navBarAppearance.shadowImage = UIImage()
            
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
            
        } else {
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.backgroundColor = .white
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
            
            DispatchQueue.global(qos: .default).async {
                
                self.postHelper.getPostsForMainFeed(getMore: getMore, sort: self.sortBy) { (posts,initialFetch)  in
                    
                    print("\(posts.count) neue dazu")
                    if initialFetch {   // Get the first batch of posts
                        
                        DispatchQueue.main.async {
                            if !self.isAppAlreadyLaunchedOnce() {
                                
                            } else if self.isItTheSecondTimeTheAppLaunches() {
                                
                                self.alert(message: NSLocalizedString("tap_blue_owen_title", comment: "go and tap it to see what this could be"), title: NSLocalizedString("tap_blue_owen_message", comment: ""))
                            } else if !self.alreadyAcceptedPrivacyPolicy() {
                                self.showGDPRAlert()
                            }
                        }
                        
                        self.posts = posts
                        let post = Post()
                        post.type = .topTopicCell
                        self.posts.insert(post, at: 0)
                        
                        //                    let adpost = Post()
                        //                    adpost.title = "ad"
                        //
                        //                    self.posts.insert(adpost, at: 4)
                        
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            
                            self.fetchesPosts = false
                            
                            // remove ActivityIndicator incl. backgroundView
                            self.view.activityStopAnimating()
                            
                            self.refreshControl?.endRefreshing()
                        }
                    } else {    // Append the next batch to the existing
                        var indexes : [IndexPath] = [IndexPath]()
                        
                        for result in posts {
                            let row = self.posts.count
                            
                            indexes.append(IndexPath(row: row, section: 0))
                            self.posts.append(result)
                        }
                        
                        DispatchQueue.main.async {
                            
                            if #available(iOS 11.0, *) {
                                self.tableView.performBatchUpdates({
                                    self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                                    self.tableView.insertRows(at: indexes, with: .bottom)
                                }, completion: { (_) in
                                    self.fetchesPosts = false
                                })
                            } else {
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
                                                let comment = Comment(commentSection: .post, sectionItemID: postID, commentID: change.document.documentID)
                                                
                                                if let isTopicPost = data["isTopicPist"] as? Bool {
                                                    comment.isTopicPost = isTopicPost
                                                }
                                                comment.author = author
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
                                                
                                                if let upvote = self.upvotes.first(where: {$0.sectionItemID == postID}) {
                                                    
                                                    self.addUpvote(comment: upvote, buttonType: button)
                                                } else {
                                                    let comment = Comment(commentSection: .post, sectionItemID: postID, commentID: change.document.documentID)
                            
                                                    comment.sectionItemID =  postID
                                                    comment.upvotes = Votes()
                                                    comment.title = title
                                                    if let _ = data["isTopicPost"] as? Bool {
                                                        comment.isTopicPost = true
                                                    }
                                                    
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
                                                self.notifications = self.notifications.filter{$0.sectionItemID != postID}
                                            }
                                        case "message":
                                            self.newMessages = self.newMessages-1
                                        case "blogPost":
                                            self.newBlogPost = self.newBlogPost-1
                                        case "upvote":
                                            if let postID = data["postID"] as? String {
                                                print("Delete upvote out of array")
                                                
                                                let count = self.upvotes.count
                                                self.upvotes = self.upvotes.filter{$0.sectionItemID != postID}
                                                
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
                            let notifications = self.newComments+self.friendRequests
                            self.setBarButtonProfileBadge(notifications: notifications, newChats: self.newMessages)
                            self.setBlogPostBadge(value: self.newBlogPost)
//                            self.setChatBadge(value: self.newMessages)
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
    
    func setBarButtonProfileBadge(notifications: Int, newChats: Int) {
        
        if notifications >= 1 {
            self.smallNumberForNotifications.text = String(notifications)
            self.smallNumberForNotifications.isHidden = false
        } else {
            self.smallNumberForNotifications.isHidden = true
        }
        
        if newChats >= 1 {
            self.smallNumberForNewChats.text = String(newChats)
            self.smallNumberForNewChats.isHidden = false
        } else {
            self.smallNumberForNewChats.isHidden = true
        }
    }
    
    func setBlogPostBadge(value: Int) {
        if let tabItems = tabBarController?.tabBar.items {
            let tabItem = tabItems[4] //CommunityCollectionVC
            
            if value != 0 {
                tabItem.badgeValue = String(value)
            } else {
                tabItem.badgeValue = nil
            }
        }
    }
    
//    func setChatBadge(value: Int) {
//        if let tabItems = tabBarController?.tabBar.items {
//            let tabItem = tabItems[1] //Chats
//            if value != 0 {
//                tabItem.badgeValue = String(value)
//            } else {
//                tabItem.badgeValue = nil
//            }
//        }
//    }

    
    // MARK: - TableViewStuff
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post = posts[indexPath.row]
        
        if post.type == .topTopicCell {
            tableView.deselectRow(at: indexPath, animated: false)
        } else {
            performSegue(withIdentifier: "showPost", sender: post)
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
                if let factVC = segue.destination as? ArgumentPageViewController {
                        factVC.fact = fact
//                    if fact.displayOption == .topic {
//                        factVC.displayMode = .topic
//                    }
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
    
    
    
    
    // MARK: - Navigation Items
    
    func loadBarButtonItem() {
        
        
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
            button.layer.borderColor = UIColor.imagineColor.cgColor
            
            
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
            view.addSubview(self.smallNumberForNewChats)
            view.addSubview(self.smallNumberForNotifications)
            
        } else {    // Wenn niemand eingeloggt
            self.loggedIn = false
            
            self.smallNumberForNotifications.isHidden = true
            self.smallNumberForNewChats.isHidden = true

            button.layer.cornerRadius = 4
            button.addTarget(self, action: #selector(self.logInButtonTapped), for: .touchUpInside)
            button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 15)
            button.setTitle("Log-In", for: .normal)
            button.setTitleColor(UIColor.imagineColor, for: .normal)

            
            view.addSubview(button)
        }
        
        let barButton = UIBarButtonItem(customView: view)
        self.navigationItem.leftBarButtonItem = barButton
        
    }
    
    
    
    let smallNumberForNotifications: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 27, y: 0, width: 14, height: 14))
        label.backgroundColor = .red
        label.clipsToBounds = true
        label.layer.cornerRadius = 7
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 10)
        label.isHidden = true
        
        return label
    }()
    
    let smallNumberForNewChats: UILabel = {
        let label = UILabel.init(frame: CGRect.init(x: 16, y: 0, width: 14, height: 14))
        label.backgroundColor = UIColor(red: 23/255, green: 145/255, blue: 255/255, alpha: 1)
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
        sideMenu.checkNotifications(invitations: self.friendRequests, notifications: notifications, newChats: self.newMessages)
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
        preferences.drawing.foregroundColor = UIColor.black
        preferences.drawing.backgroundColor = UIColor.white
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
        preferences.drawing.textAlignment = .left
        preferences.drawing.cornerRadius = 10
        preferences.drawing.shadowColor = .lightGray
        preferences.drawing.shadowOpacity = 1
        preferences.drawing.shadowOffset = .zero
        preferences.drawing.shadowRadius = 7
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
    
    // MARK: - Side Menu
    
    lazy var sideMenu: SideMenu = {
        let sideMenu = SideMenu()
        sideMenu.FeedTableView = self
        return sideMenu
    }()
    
    
    
    func sideMenuButtonTapped(whichButton: SideMenuButton, comment: Comment?) {
        
        switch whichButton {
        case .toUser:
            self.performSegue(withIdentifier: "toUserSegue", sender: nil)
        case .toFriends:
            performSegue(withIdentifier: "toFriendsSegue", sender: nil)
        case .toChats:
            performSegue(withIdentifier: "toChatsTapped", sender: nil)
        case .toSavedPosts:
            performSegue(withIdentifier: "toSavedPosts", sender: nil)
        case .toEULA:
            performSegue(withIdentifier: "toEULASegue", sender: nil)
        case .toPost:
            if let comment = comment{
                let post = Post()
                post.documentID = comment.sectionItemID
                post.isTopicPost = comment.isTopicPost
                if let user = Auth.auth().currentUser {     //Only works if you get notifications for your own posts
                    post.originalPosterUID = user.uid
                }
                performSegue(withIdentifier: "showPost", sender: post)
            }
        case .toComment:
            if let comment = comment {
                let post = Post()
                post.documentID = comment.sectionItemID
                post.isTopicPost = comment.isTopicPost
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
        let alert = UIAlertController(title: NSLocalizedString("accept_cookies_title", comment: "we got cookies"), message: NSLocalizedString("accept_cookies_message", comment: "what are out cookies about"), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("to_gdpr", comment: ""), style: .default, handler: { (_) in
            
            if let url = URL(string: "https://www.imagine.social/datenschutzerklärung-app") {
                UIApplication.shared.open(url)
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("accept_cookies", comment: ""), style: .default, handler: { (_) in
            
            self.defaults.set(true, forKey: "acceptedCookies")
            self.defaults.set(true, forKey: "askedAboutCookies")
            Analytics.setAnalyticsCollectionEnabled(true)
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("no_cookies", comment: ""), style: .cancel, handler: { (_) in
            
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

// MARK: - UISearchResultsUpdating Delegate, UISearchBar Delegate, CustomDelegate kann weg
extension FeedTableViewController: UISearchResultsUpdating, UISearchBarDelegate, CustomSearchViewControllerDelegate {
    
    func didSelectItem(item: Any) {
        if let post = item as? Post {
            performSegue(withIdentifier: "showPost", sender: post)
        } else if let user = item as? User {
            performSegue(withIdentifier: "toUserSegue", sender: user)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        searchController.searchResultsController?.view.isHidden = false
        
        let searchBar = searchController.searchBar
        let scope = searchBar.selectedScopeButtonIndex
        
        if searchBar.text! != "" {
            searchTableVC.searchTheDatabase(searchText: searchBar.text!, searchScope: scope)
        } else {
            // Clear the searchTableView
            searchTableVC.showBlankTableView()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if let text = searchBar.text {
            if text != "" {
                searchTableVC.searchTheDatabase(searchText: text, searchScope: selectedScope)
            } else {
                searchTableVC.showBlankTableView()
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

extension FeedTableViewController: JustPostedDelegate {
    func posted() {
        self.getPosts(getMore: false)
    }
}


