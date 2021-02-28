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
        
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    var statusBarView: UIView?
    
    var loggedIn = false    // For the barButtonItem
    
    var notificationListener: ListenerRegistration?
    var friendRequests = 0
    var newBlogPost = 0
    var newMessages = 0
    var newComments = 0
    var notifications = [Comment]()
    var upvotes = [Comment]()
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set up the preferences for the info views used in the whole project
        setUpEasyTipViewPreferences()
        
        // Initiliaze ScreenEdgePanRecognizer to open sideMenu
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self,
                                                                action: #selector(BarButtonItemTapped))
        screenEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenEdgeRecognizer)
        
        // Initialize the logIn or profilePicture Button
        loadBarButtonItem()
        
        // If logged in get notifications and listen for new ones
        setNotificationListener()
        // Show empty cells while fetching the posts
        setPlaceholderAndGetPosts()
        
        // Show intro slides for different features in the app
        if !self.isAppAlreadyLaunchedOnce() {
            performSegue(withIdentifier: "toIntroView", sender: nil)
        }

        // Link the delegate to switch to this view again and reload if somebody posts something
        if let viewControllers = self.tabBarController?.viewControllers {
            if let navVC = viewControllers[2] as? UINavigationController {
                if let newVC = navVC.topViewController as? NewPostViewController {
                    newVC.delegate = self
                }
            }
        }
    }
    
    override func presentInfoView() {
        //Called from BaseFeedTableVC because it is called in CellForRowAt if you are new and after 6 posts are displayed
        let infoViewShown = UserDefaults.standard.bool(forKey: "likesInfo")
        if infoViewShown == false {
            showInfoView()
        }
    }
    
    func showInfoView() {
        //Show Info View that shows what the like buttons mean and stuff like this
        let upperHeight = UIApplication.shared.statusBarFrame.height +
              self.navigationController!.navigationBar.frame.height
        let height = upperHeight+40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .likes
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(popUpView)
        }
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
        }
    }
    
    func setPlaceholderAndGetPosts() {
        // Show empty cells while fetching the posts
        var index = 0
        
        let post = Post()
        post.type = .topTopicCell
        self.posts.insert(post, at: 0)
        
        while index <= 3 {
            let post2 = Post()
            if index == 1 {
                post2.type = .picture
            } else {
                post2.type = .thought
            }
            self.posts.append(post2)
            index+=1
        }
        
        self.tableView.reloadData()
        getPosts(getMore: true)
    }
    
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
                
                self.firestoreRequest.getPostsForMainFeed(getMore: getMore, sort: self.sortBy) { (posts,initialFetch)  in
                    
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
                        self.posts.removeAll()  //to get the placeholder out
                        self.posts = posts
                        let post = Post()
                        post.type = .topTopicCell
                        self.posts.insert(post, at: 0)
                        
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
    
    /// Call to load User in SideMenu and set notifications after dismissal of the logInViewController
    func loadUser() {
        self.setNotificationListener()
        self.checkForLoggedInUser()
        self.setNotifications()
        sideMenu.showUser()
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
        // If logged in get notifications and listen for new ones
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
                                                let comment = Comment(commentSection: .post, sectionItemID: postID, commentID: change.document.documentID)
                                                
                                                if let isTopicPost = data["isTopicPist"] as? Bool {
                                                    comment.isTopicPost = isTopicPost
                                                }
                                                if let language = data["language"] as? String {
                                                    if language == "en" {
                                                        comment.sectionItemLanguage = .english
                                                    }
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
                                                    if let isTopicPost = data["isTopicPost"] as? Bool {
                                                        comment.isTopicPost = isTopicPost
                                                    }
                                                    if let language = data["language"] as? String {
                                                        if language == "en" {
                                                            comment.sectionItemLanguage = .english
                                                        }
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
    
    // MARK: - TableViewStuff
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post = posts[indexPath.row]
        
        if post.type == .topTopicCell {
            tableView.deselectRow(at: indexPath, animated: false)
        } else if post.type == .singleTopic {
            if let fact = post.fact {
                performSegue(withIdentifier: "toFactSegue", sender: fact)
            }
        } else {
//            changePostLocation(post: post)
            performSegue(withIdentifier: "showPost", sender: post)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func changePostLocation(post: Post) {
        let dataDictionary: [String: Any] = ["title": post.title, "description": post.description, "createTime": Timestamp(date: Date()), "originalPoster": post.user.userUID, "thanksCount":post.votes.thanks, "wowCount":post.votes.thanks, "haCount":post.votes.thanks, "niceCount":post.votes.thanks, "type": "picture", "report": "normal", "imageURL": post.imageURL, "imageHeight": post.mediaHeight, "imageWidth": post.mediaWidth]
        
        let ref = db.collection("Posts").document()
        
        ref.setData(dataDictionary) { (err) in
            if let error = err {
                print("error:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - PrepareForSegue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                    postVC.linkedFactPageVCNeedsHeightCorrection = true
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
                if let reportVC = segue.destination as? ReportViewController {
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
            if let fact = sender as? Community {
                if let factVC = segue.destination as? ArgumentPageViewController {
                    factVC.fact = fact
                    factVC.headerNeedsAdjustment = true
                }
            }
        }
        if segue.identifier == "goToPostsOfTopic" {
            if let fact = sender as? Community {
                if let factVC = segue.destination as? PostsOfFactTableViewController {
                    
                    factVC.fact = fact
                    self.notifyFactCollectionViewController(fact: fact)
                    
                }
            }
        }
    }
    
    func notifyFactCollectionViewController(fact: Community) {
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
        // View so there can be a small number for Invitations
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 35).isActive = true
        view.widthAnchor.constraint(equalToConstant: 35).isActive = true
        
        //create new Button for the profilePictureButton
        let button = DesignableButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)    // Apparently needed for the rounded corners
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        // If somebody is logged in add a profilePicture button to open the sidemenu
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
            
        } else {    // If nobody is logged in just show the logIn Button
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
        //Called when the sideMenu is closed with an call to action
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
                post.language = comment.sectionItemLanguage
                post.newUpvotes = comment.upvotes

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
                post.language = comment.sectionItemLanguage
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
        //Ask about the use of cookies. You can change the userdefaults later in the settings
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

extension FeedTableViewController: LogOutDelegate {

    func deleteListener() {     
        self.notificationListener?.remove()
        self.notificationListener = nil
        
        self.newComments = 0
        self.friendRequests = 0
        self.newBlogPost = 0
        self.newMessages = 0
        self.notifications.removeAll()
        
        sideMenu.removeUser()
    }
}

extension FeedTableViewController: JustPostedDelegate {
    func posted() {
        self.getPosts(getMore: false)
    }
}


