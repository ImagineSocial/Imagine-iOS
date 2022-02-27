//
//  PostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftLinkPreview
import Firebase
import YoutubePlayer_in_WKWebView
import AVKit
import FirebaseAuth
import FirebaseFirestore


class PostViewController: UIViewController, UIScrollViewDelegate {
    
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewPageControl: UIPageControl!
    
    @IBOutlet weak var imageCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentTableView: CommentTableView!
    @IBOutlet weak var feedLikeView: FeedLikeView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var descriptionView: DesignablePopUp!
    
    @IBOutlet weak var reportViewTitleLabel: UILabel!
    @IBOutlet weak var reportViewDescriptionLabel: UILabel!
    @IBOutlet weak var reportViewInfoButton: DesignableButton!
    @IBOutlet weak var reportView: DesignablePopUp!
    @IBOutlet weak var reportViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var savePostButton: DesignableButton!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var linkPreviewTitle: UILabel!
    @IBOutlet weak var linkPreviewDescription: UILabel!
    @IBOutlet weak var linkPreviewView: UIView!
    
    // hide Profile Picture
    @IBOutlet weak var leadingNameLabelToSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingNameLabelToProfilePictureConstraint: NSLayoutConstraint!
    
    
    
    // MARK: - Variables
    var post = Post()
    
    let db = FirestoreRequest.shared.db
    let handyHelper = HandyHelper.shared
    
    var ownPost = false
    var currentUser: User?
    var allowedToComment = true
    
    var centerX: NSLayoutConstraint?
    var distanceConstraint: NSLayoutConstraint?
        
    fileprivate var backUpViewHeight : NSLayoutConstraint?
    fileprivate var backUpButtonHeight : NSLayoutConstraint?
    fileprivate var imageHeightConstraint : NSLayoutConstraint?
    fileprivate var commentTableViewHeightConstraint: NSLayoutConstraint?
    
    // ImageCollectionView
    let defaultLinkString = "link-default"
    var imageURLs = [String]()
    let panoramaHeightMaximum: CGFloat = 500
    
    // Comment
    let commentIdentifier = "CommentCell"
    var floatingCommentView: CommentAnswerView?
    
    
    // GIFS
    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer?
    
    var videoPlayerItem: AVPlayerItem? = nil {
        didSet {
            avPlayer?.replaceCurrentItem(with: self.videoPlayerItem)
            avPlayer?.play()
        }
    }
    
    //Outsourced UIViews
    lazy var repostView = RepostView(viewController: self)
    lazy var linkedCommunityView = LinkedCommunityView(postViewController: self)
    
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.activityStartAnimating()
        feedLikeView.delegate = self
        
        //UI
        setUpUI()
        
        setupCollectionViews()
        
        //Scroll View
        scrollView.delegate = self
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        scrollViewTap.cancelsTouchesInView = false  // Otherwise the tap on the TableViews are not recognized
        scrollView.addGestureRecognizer(scrollViewTap)
        
        //Show/Load & Show Post
        setupViewController()
        
        //Notifications
        handyHelper.deleteNotifications(type: .comment, id: post.documentID)
        handyHelper.deleteNotifications(type: .upvote, id: post.documentID)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        //Add Observer again when the view was temporarly left for a user or a community profile
        if let commentView = floatingCommentView {
            commentView.addKeyboardObserver()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let commentView = floatingCommentView {
            commentView.removeKeyboardObserver()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let imageWidth = post.mediaWidth
        let imageHeight = post.mediaHeight
        switch post.type {
        case .multiPicture:
            
            // No Post yet
            if imageWidth == 0 || imageHeight == 0 {
                return
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width
            let newHeight = contentWidth / ratio
            
       
            imageCollectionViewHeightConstraint.constant = newHeight
            imageCollectionView.reloadData()
            
        case .panorama:
            
            // No Post yet
            if imageWidth == 0 || imageHeight == 0 {
                return
            }
            var height = imageHeight
            if height > panoramaHeightMaximum {
                height = panoramaHeightMaximum
            }
            imageCollectionViewHeightConstraint.constant = height
            imageCollectionView.reloadData()
            
        case .picture:
            
            // No Post yet
            if imageWidth == 0 || imageHeight == 0 {
                return
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width
            let newHeight = contentWidth / ratio
            
            imageCollectionViewHeightConstraint.constant = newHeight
            imageCollectionView.reloadData()
            
        case .GIF:
            
            if imageWidth == 0 || imageHeight == 0 {
                return
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width
            let newHeight = contentWidth / ratio
              
            imageCollectionViewHeightConstraint.constant = newHeight
            let frame = CGSize(width: contentWidth, height: newHeight)
            if let playLay = avPlayerLayer {
                playLay.frame.size = frame
            }
        default:
            print("No important stuff for these buggeroos")
        }
        
        if let view = floatingCommentView {
            if view.answerTextField.isFirstResponder { //If the answerview is open
                self.scrollViewDidScroll(scrollView)
            }
        }
    }
    
    //MARK: - Set Up UI
    
    private func setupCollectionViews() {
        //Comment Table View
        commentTableView.initializeCommentTableView(section: .post, notificationRecipients: self.post.notificationRecipients)
        commentTableView.commentDelegate = self
        commentTableView.post = self.post   // Absichern, wenn der Post keine Kommentare hat, brauch man auch nicht danach suchen und sich die Kosten sparen
        
        //Image Collection View
        imageCollectionView.register(MultiImageCollectionCell.self, forCellWithReuseIdentifier: MultiImageCollectionCell.identifier)
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        imageCollectionView.setCollectionViewLayout(layout, animated: true)
        imageCollectionView.bounces = false
    }
    
    func setUpUI() {
        
        feedLikeView.setDefaultButtonImages()
                
        savePostButton.tintColor = .label
        
        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButton.tintColor = Constants.green
            }
        }
    }
    
    //MARK: - Show Post
    
    func showPost() {
        
        if let user = Auth.auth().currentUser, let OP = post.user, user.uid == OP.userID { // Your own Post -> Different UI for a different Feeling. Shows like counts
            self.ownPost = true
            self.feedLikeView.setOwnCell(post: post)
        }
        
        self.view.activityStopAnimating()
        
        let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
        let descriptionText = post.description.replacingOccurrences(of: "\\n", with: newLineString)
        
        
        titleLabel.text = post.title
        createDateLabel.text = post.createTime
        feedLikeView.commentCountLabel.text = String(post.commentCount)
        
        if let fact = post.community {   // Isnt attached if you come from search
            //Need boolean wether already fetched or not
            if fact.fetchComplete {
                addLinkedCommunityView()
                setCommunity()
            } else {
                let communityRequest = CommunityRequest()
                communityRequest.getCommunity(language: post.language, community: fact, beingFollowed: false) { (fact) in
                    self.post.community = fact
                    self.addLinkedCommunityView()
                    self.setCommunity()
                    if let view = self.floatingCommentView {
                        //Otherwise the linkedFactView would be over the keyboard of the commentField
                        self.contentView.bringSubviewToFront(view)
                    }
                }
            }
        }
        
        self.setUser()
        
        if descriptionText == "" {
            self.descriptionView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        } else {
            descriptionLabel.text = descriptionText
        }
        
        if post.report == .normal {
            reportViewHeightConstraint.constant = 0
            reportView.isHidden = true
        }
                
        switch post.type {
        case .multiPicture:
            collectionViewPageControl.isHidden = false
            collectionViewPageControl.currentPage = 0
            
            guard let imageURLs = post.imageURLs else {
                return
            }
                collectionViewPageControl.numberOfPages = imageURLs.count
                if self.imageURLs.count != imageURLs.count {    // Append just once
                    self.collectionViewPageControl.numberOfPages = imageURLs.count
                    for imageURL in imageURLs {
                        
                        self.imageURLs.append(imageURL)
                        self.imageCollectionView.reloadData()
                    }
                }
        case .panorama:
            self.imageURLs.append(post.imageURL)
            
            self.imageCollectionView.isPagingEnabled = false
            self.imageCollectionView.reloadData()
        case .picture:
            if self.imageURLs.count == 0 && post.imageURL != "" {
                self.imageURLs.append(post.imageURL)
                self.imageCollectionView.reloadData()
            } else {
                return
            }
        case .GIF:
            setupGIFPlayer()
            
            if let url = URL(string: post.linkURL) {
                let item = AVPlayerItem(url: url)
                self.videoPlayerItem = item
            }
        case .link:
            if let link = post.link {
                setUpLinkButton()
                imageCollectionViewHeightConstraint.constant = 200
                linkPreviewView.isHidden = false
                self.urlLabel.text = link.shortURL
                self.linkPreviewTitle.text = link.linkTitle
                self.linkPreviewDescription.text = link.linkDescription
                self.imageCollectionView.backgroundColor = .secondarySystemBackground
                
                if let imageURL = link.imageURL {
                    self.imageURLs.append(imageURL)
                    self.imageCollectionView.reloadData()
                } else {
                    self.imageURLs.append(self.defaultLinkString)
                    self.imageCollectionView.reloadData()
                }
            } else {
                print("#Error: got no link in link post view")
            }
        case .youTubeVideo:
            setUpYouTubeVideoUI()
            if let youTubeID = post.linkURL.youtubeID {
                youTubeView.load(withVideoId: youTubeID)
            }
        case .repost:
            setUpRepostUI()
            
            if let _ = post.repost {
                showRepost()
            } else {
                // No Post yet
                return
            }
        case .thought:
            imageCollectionViewHeightConstraint.constant = 0
        default:
            print("Hier brauche ich noch was für nen Thought?")
        }
        
        if let upvotes = post.newUpvotes { // Comes from the SideMenu NotifactionCenter with upvotes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.getUpvotes(upvotes: upvotes)
            }
        }
        
        if post.toComments {    // Comes from the SideMenu NotifactionCenter with comment
            self.scrollToBottom()
        }
        imageCollectionView.reloadData()    // To load the image, when the data has to be fetched in "setUpViewController"
    }
    
    //MARK: - Show User
    
    var index = 0
    func loadUser(post: Post) {
        if post.user != nil {
            setUser()
        } else {
            if index <= 15 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.loadUser(post: post)
                    self.index+=1
                }
            }
        }
    }
    
    func setUser() {
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.width / 2
        repostView.repostProfilePictureImageView.layer.cornerRadius = repostView.repostProfilePictureImageView.frame.width / 2
        
        if self.post.anonym {
            profilePictureImageView.image = UIImage(named: "anonym-user")
            if let anonymousName = post.anonymousName {
                nameLabel.text = anonymousName
            } else {
                nameLabel.text = Constants.strings.anonymPosterName
            }
        } else {
            if let user = post.user {
                nameLabel.text = user.displayName
                
                if let imageURL = user.imageURL, let url = URL(string: imageURL) {
                    profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
            }
        }
        
        if let designOptions = self.post.designOptions {
            if designOptions.hideProfilePicture {
                leadingNameLabelToProfilePictureConstraint.isActive = false
                leadingNameLabelToSuperviewConstraint.isActive = true
                profilePictureImageView.isHidden = true
                nameLabel.font = UIFont(name: "IBMPlexSans-Medium", size: 13)
            }
        }
    }
    
    @IBAction func userButtonTapped(_ sender: Any) {
        if let user = post.user {
            if !post.anonym {
                performSegue(withIdentifier: "toUserSegue", sender: user)
            }
        } else {
            print("Kein User zu finden!")
        }
    }
    
    
    //MARK: - Set Up View Controller
    func setupViewController() {
        
        if post.user == nil && !post.anonym {

            //No post data yet
            let toComments = post.toComments
            let votes = post.newUpvotes
            FirestoreRequest.shared.getPostsFromDocumentIDs(posts: [post]) { (posts) in
                if let posts = posts {
                    if posts.count != 0 {
                        let post = posts[0]
                        
                        self.post = post
                        self.post.toComments = toComments
                        self.post.newUpvotes = votes
                        self.loadPost()
                        if post.user == nil && !post.anonym {
                            self.loadUser(post: post)
                        }
                    } else {
                        print("Kein Post bekommen")
                    }
                } else {
                    print("No Posts")
                }
            }
        } else {
            self.loadPost()
        }
    }
    
    func loadPost() {
        showPost()
        createFloatingCommentView()
    }
    
    func checkIfAlreadySaved() {
        if let user = Auth.auth().currentUser {
            let savedRef = db.collection("Users").document(user.uid).collection("saved").whereField("documentID", isEqualTo: post.documentID)
            
            savedRef.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if snap!.documents.count != 0 {
                        // Already saved
                        self.savePostButton.tintColor = Constants.green
                    }
                }
            }
        }
    }
    
    // MARK: - Linked Community View
    
    func setCommunity() {
        if let community = post.community {
            linkedCommunityView.community = community
        }
    }
    
    func addLinkedCommunityView() {
        
        // To match the width of 2 Buttons, which vary with the screensize
        //15 is the space at start/end and in between the buttons
        let voteButtonWidth = ((self.view.frame.width-(6*15))/5)
        let linkedCommunityViewWidth = voteButtonWidth*3+30
        
        let buttonHeight: CGFloat = 35
        
        contentView.addSubview(linkedCommunityView)
        linkedCommunityView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        linkedCommunityView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 15).isActive = true
        linkedCommunityView.widthAnchor.constraint(equalToConstant: linkedCommunityViewWidth).isActive = true
        linkedCommunityView.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
    }
    
    func linkedCommunityTapped() {
        
        if let fact = post.community {
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        }
    }
    
    //MARK: - RepostView
    
    func setUpRepostUI() {
        contentView.addSubview(repostView)
        repostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        repostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        repostView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        repostView.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor).isActive = true
    }
    
    func showRepost() {
        if let repost = post.repost {
            
            //Calculate and set the height of the repost image
            let ratio = repost.mediaWidth / repost.mediaHeight
            let contentWidth = self.contentView.frame.width-40
            let newHeight = contentWidth / ratio
            
            repostView.repostImageView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
            
            //Set the imageCOllectionViewHeight as this is the layout boundary for the repostView
            imageCollectionViewHeightConstraint.constant = newHeight+135
            
            //set title, user etc. in the repostView
            repostView.repost = repost
        }
    }
    
    // Repost functions
    func repostViewTapped() {
        if let repost = post.repost {
            let postVC = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostViewController
            postVC.post = repost
            self.navigationController?.pushViewController(postVC, animated: true)
        }
    }
    
    func repostUserTapped() {
        if let repost = post.repost {
            if let repostUser = repost.user {
                if !repost.anonym {
                    self.toUserTapped(user: repostUser)
                }
            } else {
                print("no user to find")
            }
        }
    }
    
    //MARK: - Link Post
    
    func setUpLinkButton() {
        contentView.addSubview(linkButton)
        linkButton.leadingAnchor.constraint(equalTo: imageCollectionView.leadingAnchor).isActive = true
        linkButton.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor).isActive = true
        linkButton.widthAnchor.constraint(equalTo: imageCollectionView.widthAnchor).isActive = true
        linkButton.heightAnchor.constraint(equalTo: imageCollectionView.heightAnchor).isActive = true
    }
    
    let linkButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(linkTapped), for: .touchUpInside)
        
        return button
    }()
    
    @objc func linkTapped() {
        let vc = WebVC()
        vc.post = post
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isToolbarHidden = false
        
        present(navVC, animated: true)
    }
    
    //MARK: - YouTube Post
    
    func setUpYouTubeVideoUI() {
        imageCollectionViewHeightConstraint.constant = 200
        contentView.addSubview(youTubeView)
        youTubeView.leadingAnchor.constraint(equalTo: imageCollectionView.leadingAnchor).isActive = true
        youTubeView.trailingAnchor.constraint(equalTo: imageCollectionView.trailingAnchor).isActive = true
        youTubeView.topAnchor.constraint(equalTo: imageCollectionView.topAnchor).isActive = true
        youTubeView.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor).isActive = true
        youTubeView.layoutIfNeeded() //?
    }
    
    let youTubeView: WKYTPlayerView = {
        let ytv = WKYTPlayerView()
        ytv.translatesAutoresizingMaskIntoConstraints = false
        
        return ytv
    }()
    
    //MARK: - Like Buttons
    
    func updateLikeCount(button: DesignableButton) {
        if let _ = Auth.auth().currentUser {
            var voteButton: VoteButton
            switch button {
            case feedLikeView.thanksButton:
                post.votes.thanks += 1
                voteButton = .thanks
            case feedLikeView.wowButton:
                post.votes.wow += 1
                voteButton = .wow
            case feedLikeView.haButton:
                post.votes.ha += 1
                voteButton = .ha
            case feedLikeView.niceButton:
                post.votes.nice += 1
                voteButton = .nice
            default:
                voteButton = .thanks
                break
            }
            
            feedLikeView.showLikeCount(for: voteButton, post: post)
            handyHelper.updatePost(button: voteButton, post: post)
        } else {
            notLoggedInAlert()
        }
    }
    
    
    func getUpvotes(upvotes: Votes) {
        
        var upvoteArray = [DesignableButton]()
        
        if upvotes.thanks != 0 {
            var index = 0
            while index <= upvotes.thanks {
                upvoteArray.append(self.feedLikeView.thanksButton)
                index+=1
            }
        }
        
        if upvotes.wow != 0 {
            var index = 0
            while index <= upvotes.wow {
                upvoteArray.append(self.feedLikeView.wowButton)
                index+=1
            }
        }
        
        if upvotes.ha != 0 {
            var index = 0
            while index <= upvotes.ha {
                upvoteArray.append(self.feedLikeView.haButton)
                index+=1
            }
        }
        
        if upvotes.nice != 0 {
            var index = 0
            while index <= upvotes.nice {
                upvoteArray.append(self.feedLikeView.niceButton)
                index+=1
            }
        }
        
        showUpvotes(buttons: upvoteArray)
    }
    
    func showUpvotes(buttons: [DesignableButton]) {
        var buttons = buttons
        if buttons.count != 0 {
           let button = buttons[0]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showButtonText(button: button)
                buttons.removeFirst()
                self.showUpvotes(buttons: buttons)
            }
        }
    }
    
    //MARK: - Like Button Animation
    
    func showButtonText(button: DesignableButton) {

        self.contentView.addSubview(buttonLabel)
        buttonLabel.alpha = 1
        button.setTitleColor(.label, for: .normal)
        
        if let _ = centerX {
            centerX!.isActive = false
            distanceConstraint!.isActive = false
        }
        
        centerX = buttonLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor)
        centerX!.priority = UILayoutPriority(rawValue: 250)
        centerX!.isActive = true
        
        distanceConstraint = buttonLabel.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -5)
        distanceConstraint!.priority = UILayoutPriority(rawValue: 250)
        distanceConstraint!.isActive = true
        self.view.layoutIfNeeded()
                
        switch button {
        case feedLikeView.thanksButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_thanks", comment: "thanks and stuff")
        case feedLikeView.wowButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_wow", comment: "wow and stuff")
        case feedLikeView.haButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_ha", comment: "ha and stuff")
        case feedLikeView.niceButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_nice", comment: "nice and stuff")
        default:
            buttonLabel.text = "so nicht"
        }
        
        distanceConstraint!.constant = -50
        
        UIView.animate(withDuration: 1.5) {
            self.view.layoutIfNeeded()
            self.buttonLabel.alpha = 0
        }
    }
    
    let buttonLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        //        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        label.alpha = 0.8
        label.backgroundColor = .clear
        
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 2
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = CGSize(width: 0, height: 3)
        label.layer.masksToBounds = false
        
        return label
    }()
    
    
    // MARK: - GIF Player
    
    func setupGIFPlayer(){
        self.avPlayer = AVPlayer(playerItem: self.videoPlayerItem)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avPlayer?.volume = 0
        avPlayer?.actionAtItemEnd = .none
        
        avPlayerLayer?.frame = self.view.bounds
        self.imageCollectionView.layer.addSublayer(avPlayerLayer!)
        
        //To Loop the Video
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer?.currentItem)
    }
    
    //To Loop the Video
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    //MARK: - Button Responder
    @objc func postImageTapped() {
        let pinchVC = PinchToZoomViewController()
        
        switch post.type {
        case .repost:
            pinchVC.post = self.post.repost
        default:
            pinchVC.post = self.post
        }
        
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
    
    
    @IBAction func savePostTapped(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            let ref = db.collection("Users").document(user.uid).collection("saved").document(post.documentID)
            
            var data: [String:Any] = ["createTime": Timestamp(date: Date())]
            
            if post.isTopicPost {
                data["isTopicPost"] = true
            }
                    
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error saving this post: \(error.localizedDescription)")
                } else {
                    print("Successfully saved")
                    self.savePostButton.tintColor = Constants.green
                }
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        performSegue(withIdentifier: "reportSegue", sender: post)
    }
    
    //MARK: - Translate Post
    
    let translatePostButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(translatePostTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "translate"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label
        
        return button
    }()
    
    @objc func translatePostTapped() {
        if post.type == .picture {
            performSegue(withIdentifier: "toTranslateSegue", sender: post)
        } else {
            self.alert(message: NSLocalizedString("error_translate_not_supported", comment: "just picture is supported at the moment"))
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "toFactSegue":
            if let community = sender as? Community, let communityVC = segue.destination as? CommunityPageVC {
                communityVC.community = community
            }
        case "goToPostsOfTopic":
            if let community = sender as? Community, let navCon = segue.destination as? UINavigationController, let factVC = navCon.topViewController as? CommunityFeedTableVC {
                factVC.community = community
                factVC.needNavigationController = true
            }
        case "toUserSegue":
            if let chosenUser = sender as? User, let userVC = segue.destination as? UserFeedTableViewController {
                userVC.userOfProfile = chosenUser
                userVC.currentState = .otherUser
                
            }
        case "reportSegue":
            if let chosenPost = sender as? Post, let reportVC = segue.destination as? ReportViewController {
                reportVC.post = chosenPost
            }
        case "toTranslateSegue":
            if let navVC = segue.destination as? UINavigationController, let repostVC = navVC.topViewController as? RepostViewController, let chosenPost = sender as? Post {
                repostVC.post = chosenPost
                repostVC.repost = .translation
            }
        default:
            break
        }
    }
    
    //MARK: - CommentAnswerView
    
    func createFloatingCommentView() {
        let viewHeight = self.view.frame.height
        
        guard floatingCommentView == nil else { return }
        
        let commentViewHeight: CGFloat = 60
        floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: viewHeight-commentViewHeight, width: self.view.frame.width, height: commentViewHeight))
        
        guard let floatingCommentView = floatingCommentView else { return }

        floatingCommentView.delegate = self
        self.contentView.addSubview(floatingCommentView)
        
        floatingCommentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        floatingCommentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        floatingCommentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
        let bottomConstraint = floatingCommentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        bottomConstraint.isActive = true
        
        floatingCommentView.addKeyboardObserver()
        floatingCommentView.commentSection = .post
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = floatingCommentView {
            view.answerTextField.resignFirstResponder()
        }
    }
    
    func scrollToBottom() {
        // Scroll to the end of the view
    }
    
    
    //MARK: - ScrollViewDelegate
    
    @objc func scrollViewTapped() {
        if let view = floatingCommentView {
            view.answerTextField.resignFirstResponder()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if scrollView == self.scrollView {
            if let view = floatingCommentView {
                let offset = scrollView.contentOffset.y
                let screenHeight = self.view.frame.height
                
                view.adjustPositionForScroll(contentOffset: offset, screenHeight: screenHeight)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == imageCollectionView {
            if let indexPath = imageCollectionView.indexPathsForVisibleItems.first {
                collectionViewPageControl.currentPage = indexPath.row
            }
        }
    }
}

extension PostViewController: FeedLikeViewDelegate {
    func registerVote(button: DesignableButton) {
        self.updateLikeCount(button: button)
    }
}
