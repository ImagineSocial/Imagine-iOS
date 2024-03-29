//
//  FeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage
import Reachability
import EasyTipView


class FeedTableViewController: BaseFeedTableViewController, UNUserNotificationCenterDelegate {
    
        
    //MARK: - Variables
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    var loggedIn = false    // For the barButtonItem
    
    var notificationListener: ListenerRegistration?
    var friendRequests = 0
    var newBlogPost = 0
    var newMessages = 0
    var newComments = 0
    var notifications = [Comment]()
    var upvotes = [Comment]()
    
    let defaults = UserDefaults.standard
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpEasyTipViewPreferences()
        
        // Initiliaze ScreenEdgePanRecognizer to open sideMenu
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(BarButtonItemTapped))
        screenEdgeRecognizer.edges = .left
        view.addGestureRecognizer(screenEdgeRecognizer)
        
        // Initialize the logIn or profilePicture Button
        loadBarButtonItem()
        
        setNotificationListener()
        
        setPlaceholders()
        getPosts()
        
        // Show intro slides for different features in the app
        if !self.isAppAlreadyLaunchedOnce() {
            performSegue(withIdentifier: "toIntroView", sender: nil)
        }

        // Link the delegate to switch to this view again and reload if somebody posts something
        if let viewControllers = self.tabBarController?.viewControllers, let navVC = viewControllers[2] as? UINavigationController, let newVC = navVC.topViewController as? NewPostVC {
            newVC.delegate = self
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.navigationController?.hidesBarsOnSwipe = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        setupNavigationbar()
        
        DispatchQueue.main.async {
            self.checkForLoggedInUser()
        }
    }
    
    override func didReceiveMemoryWarning() {
        print("Memory Pressure triggered")
        SDImageCache.shared.clearMemory()
        
    }
    
    private func setupNavigationbar() {
        self.navigationController?.hidesBarsOnSwipe = true
        navigationItem.largeTitleDisplayMode = .never
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        navBarAppearance.titleTextAttributes = [.font: UIFont(name: "IBMPlexSans-Medium", size: 25) ?? .systemFont(ofSize: 25)]
        navBarAppearance.largeTitleTextAttributes = [.font: UIFont(name: "IBMPlexSans-SemiBold", size: 35) ?? UIFont.systemFont(ofSize: 35, weight: .semibold)]
        
        self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    //MARK: - Get Data
    
    @objc override func getPosts() {
        // If "getMore" is true, you want to get more Posts, or the initial batch of 20 Posts, if not you want to refresh the current feed
        
        guard isConnected(), !fetchInProgress else {
            fetchRequested = !isConnected()
            return
        }
        
        view.activityStartAnimating()
        fetchInProgress = true
        
        DispatchQueue.global(qos: .background).async {
            
            self.firestoreManager.getPostsForMainFeed { posts in
                guard let posts = posts else {
                    return
                }
                
                if posts.isEmpty {
                    self.returnedPostsAreEmpty()
                    return
                }
                                
                self.placeholderAreShown ? self.setPosts(posts) : self.appendPosts(posts)
            }
            
            return
            
            // Das hier noch irgendwie
            DispatchQueue.main.async {
                if !self.alreadyAcceptedPrivacyPolicy() {
                    self.showGDPRAlert()
                }
            }
        }
    }
    
    
    // MARK: - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let post = posts[indexPath.row]
        
        if post.type == .singleTopic {
            if let fact = post.community {
                performSegue(withIdentifier: "toFactSegue", sender: fact)
            }
        } else {
            performSegue(withIdentifier: "showPost", sender: post)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK:- Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "showPost":
            if let chosenPost = sender as? Post, let postVC = segue.destination as? PostViewController {
                postVC.post = chosenPost
            }
        case "toIntroView":
            if let introVC = segue.destination as? SwipeCollectionViewController {
                introVC.diashow = .intro
            }
        case "meldenSegue":
            if let chosenPost = sender as? Post, let reportVC = segue.destination as? ReportViewController {
                reportVC.post = chosenPost
            }
        case "toUserSegue":
            if let userVC = segue.destination as? UserFeedTableViewController {
                if let chosenUser = sender as? User {   // Another User
                    userVC.user = chosenUser
                    userVC.currentState = .otherUser
                } else { // The CurrentUser
                    userVC.delegate = self
                    userVC.currentState = .ownProfile
                }
            }
        case "toBlogPost":
            if let chosenPost = sender as? BlogPost, let blogVC = segue.destination as? BlogPostViewController {
                blogVC.blogPost = chosenPost
            }
        case "toLogInSegue":
            if let vc = segue.destination as? LogInViewController {
                vc.delegate = self
            }
        case "toFactSegue":
            if let community = sender as? Community, let factVC = segue.destination as? CommunityPageVC {
                factVC.community = community
            }
        case "goToPostsOfTopic":
            if let community = sender as? Community, let factVC = segue.destination as? CommunityFeedTableVC {
                factVC.community = community
                self.notifyFactCollectionViewController(community: community)
            }
        default:
            break
        }
    }
    
    //MARK:- Hide/Show Tab Bar
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {

        let yValue = scrollView.panGestureRecognizer.translation(in: scrollView).y
        if yValue < -0.1 {
            //hide tabBar
            changeTabBar(hidden: true, animated: true)
        } else if yValue > 0.1 {
            //show tabBar
            changeTabBar(hidden: false, animated: true)
        }
    }
    
    func changeTabBar(hidden:Bool, animated: Bool) {
        guard let tabBar = self.tabBarController?.tabBar else {
            return
        }
        if tabBar.isHidden == hidden{
            return
        }
        
        let frame = tabBar.frame
        let frameMinY = frame.minY  //lower end of tabBar
        let offset = hidden ? frame.size.height : -frame.size.height
        let viewHeight = self.view.frame.height
        
        //hidden but moved back up after moving app to background
        if frameMinY < viewHeight && tabBar.isHidden {
            tabBar.alpha = 0
            tabBar.isHidden = false

            UIView.animate(withDuration: 0.5) {
                tabBar.alpha = 1
            }
            return
        }

        let duration:TimeInterval = (animated ? 0.5 : 0.0)
        tabBar.isHidden = false

        UIView.animate(withDuration: duration, animations: {
            tabBar.frame = frame.offsetBy(dx: 0, dy: offset)
        }, completion: { (true) in
            tabBar.isHidden = hidden
        })
    }
    
    //MARK:- Register Recent Community
    func notifyFactCollectionViewController(community: Community) {
        if let viewControllers = self.tabBarController?.viewControllers, let navVC = viewControllers[3] as? UINavigationController, let communityVC = navVC.topViewController as? CommunityCollectionVC {
            communityVC.registerRecentFact(community: community)
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
                
                if AuthenticationManager.shared.isLoggedIn {
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
        
        let user = Auth.auth().currentUser
        let loggedIn = user != nil
        
        // View so there can be a small number for Invitations
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.constrain(width: loggedIn ? 35 : 30, height: loggedIn ? 35 : 30)
        
        //create new Button for the profilePictureButton
        let button = DesignableButton()
        button.layer.masksToBounds = true
        
        view.addSubview(button)
        
        button.constrain(width: loggedIn ? 35 : 30, height: loggedIn ? 35 : 30)
        button.layer.cornerRadius = (loggedIn ? 35 : 30) / 2
        
        // If somebody is logged in add a profilePicture button to open the sidemenu
        if let user = user {
            self.loggedIn = true
            
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
            
            view.addSubview(smallNumberForNotifications)
            smallNumberForNotifications.constrain(top: view.topAnchor, trailing: view.trailingAnchor, paddingTop: -4, paddingTrailing: 4, width: 14, height: 14)
            
        } else {    // If nobody is logged in just show the logIn Button
            self.loggedIn = false
            
            self.smallNumberForNotifications.isHidden = true

            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(self, action: #selector(self.logInButtonTapped), for: .touchUpInside)
            button.setImage(UIImage(named: "login"), for: .normal)
            button.tintColor = .imagineColor
        }
        
        let barButton = UIBarButtonItem(customView: view)
        self.navigationItem.leftBarButtonItem = barButton
        
    }
    
    
    
    let smallNumberForNotifications: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = Constants.blue
        label.clipsToBounds = true
        label.layer.cornerRadius = 7
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.standard(size: 10)
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
                self.getPosts()
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
        case .toPost, .toComment:
            if let comment = comment {
                let post = Post(type: .picture, title: "", createdAt: Date())
                post.documentID = comment.sectionItemID
                post.isTopicPost = comment.isTopicPost
                post.language = comment.sectionItemLanguage
                
                performSegue(withIdentifier: "showPost", sender: post)
            }
        default:
            break
        }
        
    }
    
    //MARK: Side Menu User
    
    func checkForLoggedInUser() {
        if AuthenticationManager.shared.isLoggedIn {
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
    
    //MARK: Side Menu Notifications
    
    func setNotifications() {   // Ask for persmission to send Notifications
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.registerForPushNoticications(application: UIApplication.shared)
        }
    }
    
    /// If logged in get notifications and listen for new ones
    func setNotificationListener() {
        if let _ = notificationListener {
            print("Listener already Set")
            return
        } else {
            print("Set listener")
            if let userID = AuthenticationManager.shared.userID {
                let notRef = db.collection("Users").document(userID).collection("notifications")
                
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
                                                
                                                if let isTopicPost = data["isTopicPost"] as? Bool {
                                                    comment.isTopicPost = isTopicPost
                                                }
                                                if let language = data["language"] as? String {
                                                    if language == "en" {
                                                        comment.sectionItemLanguage = .en
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
                                                            comment.sectionItemLanguage = .en
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
        if var votes = comment.upvotes {

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
        
        if newChats >= 1 {
            self.smallNumberForNotifications.text = String(newChats)
            self.smallNumberForNotifications.isHidden = false
        } else {
            self.smallNumberForNotifications.isHidden = true
        }
        
        if notifications >= 1 {
            self.smallNumberForNotifications.text = String(notifications)
            self.smallNumberForNotifications.isHidden = false
        } else if newChats == 0 {
            self.smallNumberForNotifications.isHidden = true
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
    
    //MARK:- Info Views
    override func presentInfoView() {
        //Called from BaseFeedTableVC because it is called in CellForRowAt if you are new and after 6 posts are displayed
        let infoViewShown = UserDefaults.standard.bool(forKey: "likesInfo")
        if infoViewShown == false {
            showInfoView()
        }
    }
    
    func showInfoView() {
        //Show Info View that shows what the like buttons mean and stuff like this
        let height = topbarHeight + 40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .likes
        
        if let window = UIApplication.keyWindow() {
            window.addSubview(popUpView)
        }
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
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
    
    // MARK: EasyTipViewPreferences
    
    /// Set up the preferences for the info views used in the whole project
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
        preferences.positioning.bubbleInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        preferences.positioning.maxWidth = self.view.frame.width-40
        // Maximum of 800 Words
        
        EasyTipView.globalPreferences = preferences
    }
}


// MARK: - DismissDelegate

extension FeedTableViewController: DismissDelegate {
    
    /// Call to load User in SideMenu and set notifications after dismissal of the logInViewController
    func loadUser() {
        setNotificationListener()
        checkForLoggedInUser()
        setNotifications()
        sideMenu.showUser()
        
        reloadFeed()
        getPosts()
    }
}

// MARK: - LogOutDelegate
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
        checkForLoggedInUser()
    }
}

// MARK: - JustPostedDelegate

extension FeedTableViewController: JustPostedDelegate {
    func posted() {
        self.getPosts()
    }
}


