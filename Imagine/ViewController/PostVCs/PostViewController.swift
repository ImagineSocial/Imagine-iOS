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
    
    
    //MARK:- IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewPageControl: UIPageControl!
    
    @IBOutlet weak var imageCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentTableView: CommentTableView!
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var wowButton: DesignableButton!
    @IBOutlet weak var haButton: DesignableButton!
    @IBOutlet weak var niceButton: DesignableButton!
    @IBOutlet weak var commentCountLabel: UILabel!
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
    
    //hide Profile Picture
    @IBOutlet weak var leadingNameLabelToSuperviewConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingNameLabelToProfilePictureConstraint: NSLayoutConstraint!
    
    
    
    //MARK:- Variables
    var post = Post()
    
    let db = Firestore.firestore()
    let handyHelper = HandyHelper()
    
    var ownPost = false
    var currentUser: User?
    var allowedToComment = true
    
    var centerX: NSLayoutConstraint?
    var distanceConstraint: NSLayoutConstraint?
    
    var linkedFactPageVCNeedsHeightCorrection = false   //If it comes from mainFeed it needs to adjust height of communityHeader
    
    fileprivate var backUpViewHeight : NSLayoutConstraint?
    fileprivate var backUpButtonHeight : NSLayoutConstraint?
    fileprivate var imageHeightConstraint : NSLayoutConstraint?
    fileprivate var commentTableViewHeightConstraint: NSLayoutConstraint?
    
    //ImageCollectionView
    let defaultLinkString = "link-default"
    var imageURLs = [String]()
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    let identifier = "MultiPictureCell"
    let panoramaHeightMaximum: CGFloat = 500
    
    //Comment
    let commentIdentifier = "CommentCell"
    var floatingCommentView: CommentAnswerView?
    
    
    //GIFS
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
    
    
    //MARK:- View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.activityStartAnimating()
        
        //UI
        setUpUI()
        
        //Comment Table View
        commentTableView.initializeCommentTableView(section: .post, notificationRecipients: self.post.notificationRecipients)
        commentTableView.commentDelegate = self
        commentTableView.post = self.post   // Absichern, wenn der Post keine Kommentare hat, brauch man auch nicht danach suchen und sich die Kosten sparen
        
        //Image Collection View
        imageCollectionView.register(UINib(nibName: "MultiPictureCollectionCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        imageCollectionView.setCollectionViewLayout(layout, animated: true)
        imageCollectionView.bounces = false
        
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
        
//        if contentView.frame.height != 0 {  //ScrollView got set
//            if scrollView.frame.height > contentView.frame.height {
//                //To get the contentView up to the bottom, so the keyboard works even when small pictures or just a link without comments is displayed
//                contentView.heightAnchor.constraint(equalToConstant: scrollView.frame.height).isActive = true
//            }
//        }
    }
    
    //MARK:- Set Up UI
    
    func setUpUI() {
        
        //Buttons are too ugly without the proper ratio when they load so they appear a  bit later
        setDefaultLikeButtons()
        
        UIView.animate(withDuration: 0.3) {
            self.thanksButton.alpha = 1
            self.wowButton.alpha = 1
            self.niceButton.alpha = 1
            self.haButton.alpha = 1
        }
        
        //navigationBar
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationController?.navigationBar.shadowImage = UIImage() //"Doesnt work")
        
        //Save Post Button
        if #available(iOS 13.0, *) {
            savePostButton.tintColor = .label
        } else {
            savePostButton.tintColor = .black
        }
        
        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButton.tintColor = Constants.green
            }
        }
    }
    
    //MARK:- Show Post
    
    func showPost() {
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        if let user = Auth.auth().currentUser {
            if user.uid == post.originalPosterUID { // Your own Post -> Different UI for a different Feeling. Shows like counts
                self.ownPost = true
                
                for button in buttons {
                    button.setImage(nil, for: .normal)
                    button.layer.borderWidth = 0
                    button.setTitleColor(.white, for: .normal)
                    
                    if #available(iOS 13.0, *) {
                        button.backgroundColor = .tertiaryLabel
                    } else {
                        button.backgroundColor = .darkGray
                    }
                }
                
                self.thanksButton.setTitle(String(post.votes.thanks), for: .normal)
                self.wowButton.setTitle(String(post.votes.wow), for: .normal)
                self.haButton.setTitle(String(post.votes.ha), for: .normal)
                self.niceButton.setTitle(String(post.votes.nice), for: .normal)
                                
            }
        }
        
        self.view.activityStopAnimating()
        
        let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
        let descriptionText = post.description.replacingOccurrences(of: "\\n", with: newLineString)
        
        
        titleLabel.text = post.title
        createDateLabel.text = post.createTime
        commentCountLabel.text = String(post.commentCount)
        
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
                
                if #available(iOS 13.0, *) {
                    self.imageCollectionView.backgroundColor = .secondarySystemBackground
                } else {
                    self.imageCollectionView.backgroundColor = .ios12secondarySystemBackground
                }
                
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
    
    //MARK:- Show User
    
    var index = 0
    func loadUser(post: Post) {
        if post.user.displayName != "" {
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
            nameLabel.text = post.user.displayName
            
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, completed: nil)
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
        if post.originalPosterUID != "" {
            if !post.anonym {
                performSegue(withIdentifier: "toUserSegue", sender: post.user)
            }
        } else {
            print("Kein User zu finden!")
        }
    }
    
    
    //MARK:- Set Up View Controller
    func setupViewController() {
        
        if post.user.displayName == "" && !post.anonym {

            //No post data yet
            let toComments = post.toComments
            let votes = post.newUpvotes
            FirestoreRequest().getPostsFromDocumentIDs(posts: [post]) { (posts) in
                if let posts = posts {
                    if posts.count != 0 {
                        let post = posts[0]
                        
                        self.post = post
                        self.post.toComments = toComments
                        self.post.newUpvotes = votes
                        self.loadPost()
                        if post.user.displayName == "" && !post.anonym {
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
    
    // MARK:- Linked Community View
    
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
        
        print("linkedComm tapped: ", post.community?.title)
        if let fact = post.community {
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        }
    }
    
    //MARK:- RepostView
    
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
            if repost.originalPosterUID != "" {
                if !repost.anonym {
                    self.toUserTapped(user: repost.user)
                }
            } else {
                print("no user to find")
            }
        }
    }
    
    //MARK:- Link Post
    
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
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    //MARK:- YouTube Post
    
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
    
    //MARK:- Like Buttons
    
    func setLikeButtonTitle(post: Post, button: DesignableButton) {
        var title = String(post.votes.thanks)
        
        switch button {
        case wowButton:
            title = String(post.votes.wow)
        case haButton:
            title = String(post.votes.ha)
        case niceButton:
            title = String(post.votes.nice)
        default:
            title = String(post.votes.thanks)
        }
        
        button.setImage(nil, for: .normal)
        button.setTitle(title, for: .normal)
    }
    
    func setDefaultLikeButtons() {
        
        let buttons = [thanksButton!, wowButton!, haButton!, niceButton!]
        
        for button in buttons {
            button.imageView?.contentMode = .scaleAspectFit
            button.layer.borderWidth = 0.5
            button.layer.cornerRadius = 4
            if #available(iOS 13.0, *) {
                button.setTitleColor(.label, for: .normal)
                button.tintColor = .label
                button.layer.borderColor = UIColor.secondaryLabel.cgColor
            } else {
                button.setTitleColor(.black, for: .normal)
                button.tintColor = .black
                button.layer.borderColor = UIColor.black.cgColor
            }
        }
    }
    
    @IBAction func thanksTapped(_ sender: Any) {
        thanksButton.isEnabled = false
        updateLikeCount(button: .thanks)
    }
    
    @IBAction func wowTapped(_ sender: Any) {
        wowButton.isEnabled = false
        updateLikeCount(button: .wow)
    }
    
    @IBAction func haTapped(_ sender: Any) {
        haButton.isEnabled = false
        updateLikeCount(button: .ha)
    }
    
    @IBAction func niceTapped(_ sender: Any) {
        niceButton.isEnabled = false
        updateLikeCount(button: .nice)
    }
    
    func updateLikeCount(button: VoteButton) {
        if let _ = Auth.auth().currentUser {
            
            var desButton = DesignableButton()
            switch button {
            case .thanks:
                self.post.votes.thanks+=1
                desButton = self.thanksButton
            case .wow:
                self.post.votes.wow+=1
                desButton = self.wowButton
            case .ha:
                desButton = self.haButton
                self.post.votes.ha+=1
            case .nice:
                desButton = self.niceButton
                self.post.votes.nice+=1
            }
            
            handyHelper.updatePost(button: button, post: self.post)
            showButtonText(button: desButton)
            setLikeButtonTitle(post: self.post, button: desButton)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    func getUpvotes(upvotes: Votes) {
        
        var upvoteArray = [DesignableButton]()
        
        if upvotes.thanks != 0 {
            var index = 0
            while index <= upvotes.thanks {
                upvoteArray.append(self.thanksButton)
                index+=1
            }
        }
        
        if upvotes.wow != 0 {
            var index = 0
            while index <= upvotes.wow {
                upvoteArray.append(self.wowButton)
                index+=1
            }
        }
        
        if upvotes.ha != 0 {
            var index = 0
            while index <= upvotes.ha {
                upvoteArray.append(self.haButton)
                index+=1
            }
        }
        
        if upvotes.nice != 0 {
            var index = 0
            while index <= upvotes.nice {
                upvoteArray.append(self.niceButton)
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
    
    //MARK:- Like Button Animation
    
    func showButtonText(button: DesignableButton) {

        self.contentView.addSubview(buttonLabel)
        buttonLabel.alpha = 1
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        
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
        case thanksButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_thanks", comment: "thanks and stuff")
        case wowButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_wow", comment: "wow and stuff")
        case haButton:
            buttonLabel.text = NSLocalizedString("buttonLabel_ha", comment: "ha and stuff")
        case niceButton:
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
    
    //MARK:- Translate Post
    
    let translatePostButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(translatePostTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "translate"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
            button.tintColor = .label
        } else {
            button.setTitleColor(.black, for: .normal)
            button.tintColor = .black
        }
        
        return button
    }()
    
    @objc func translatePostTapped() {
        if post.type == .picture {
            performSegue(withIdentifier: "toTranslateSegue", sender: post)
        } else {
            self.alert(message: NSLocalizedString("error_translate_not_supported", comment: "just picture is supported at the moment"))
        }
    }
    
    //MARK:- Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toFactSegue" {
            if let fact = sender as? Community {
                if let factVC = segue.destination as? CommunityPageViewController {
                    factVC.fact = fact
                    if linkedFactPageVCNeedsHeightCorrection {
                        factVC.headerNeedsAdjustment = true
                    }
                }
            }
        }
        
        if segue.identifier == "goToPostsOfTopic" {
            if let fact = sender as? Community {
                if let navCon = segue.destination as? UINavigationController {
                    if let factVC = navCon.topViewController as? CommunityPostTableViewController {
                        factVC.fact = fact
                        factVC.needNavigationController = true
                    }
                }
            }
        }
        
        if segue.identifier == "toUserSegue" {
            if let chosenUser = sender as? User {
                if let userVC = segue.destination as? UserFeedTableViewController {
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                    
                }
            }
        }
        if segue.identifier == "goToLink" {
            if let post = sender as? Post {
                if let webVC = segue.destination as? WebViewController {
                    webVC.post = post
                }
            }
        }
        if segue.identifier == "reportSegue" {
            if let chosenPost = sender as? Post {
                if let reportVC = segue.destination as? ReportViewController {
                    reportVC.post = chosenPost
                    
                }
            }
        }
        if segue.identifier == "toTranslateSegue" {
            if let navVC = segue.destination as? UINavigationController {
                if let repostVC = navVC.topViewController as? RepostViewController {
                    if let chosenPost = sender as? Post {
                        repostVC.post = chosenPost
                        repostVC.repost = .translation
                    }
                }
            }
        }
    }
    
    //MARK:- CommentAnswerView
    func createFloatingCommentView() {
        let viewHeight = self.view.frame.height
        let screenHeight = UIScreen.main.bounds.height
        
        if viewHeight == screenHeight { // I dont know why, but they are the same for one cyrcle, probably the view is not loaded right
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.createFloatingCommentView()
                
                return
            }
        } else {
            if floatingCommentView == nil {
                let commentViewHeight: CGFloat = 60
                floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: viewHeight-commentViewHeight, width: self.view.frame.width, height: commentViewHeight))
                
                
                floatingCommentView!.delegate = self
                self.contentView.addSubview(floatingCommentView!)
                
                floatingCommentView!.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
                floatingCommentView!.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
                let bottomConstraint = floatingCommentView!.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
                    bottomConstraint.isActive = true
                floatingCommentView!.bottomConstraint = bottomConstraint
                floatingCommentView!.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
                floatingCommentView!.addKeyboardObserver()
                floatingCommentView!.commentSection = .post
                
                self.contentView.bringSubviewToFront(floatingCommentView!)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = floatingCommentView {
            view.answerTextField.resignFirstResponder()
        }
    }
    
    func scrollToBottom() {
        // Scroll to the end of the view
    }
    
    
    //MARK:- ScrollViewDelegate
    
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

//MARK:- Comment extensions
extension PostViewController: CommentTableViewDelegate, CommentViewDelegate {
    
    func notLoggedIn() {
        self.notLoggedInAlert()
    }
    
    func doneSaving() {
        if let view = self.floatingCommentView {
            view.doneSaving()
        }
    }
    
    func sendButtonTapped(text: String, isAnonymous: Bool, answerToComment: Comment?) {
        
        commentTableView.saveCommentInDatabase(bodyString: text, isAnonymous: isAnonymous, answerToComment: answerToComment)
    }
    
    func recipientChanged(isActive: Bool, userUID: String) {
        if isActive {
            self.post.notificationRecipients.append(userUID)
        } else {
            let newList = self.post.notificationRecipients.filter { $0 != userUID }
            self.post.notificationRecipients = newList
        }
    }
    
    func notAllowedToComment() {
        if let view = floatingCommentView {
            view.answerTextField.text = ""
        }
    }
    
    func commentTypingBegins() {
        
    }
    
    func commentGotReported(comment: Comment) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let reportViewController = storyBoard.instantiateViewController(withIdentifier: "reportVC") as! ReportViewController
        reportViewController.reportComment = true
        reportViewController.modalTransitionStyle = .coverVertical
        reportViewController.modalPresentationStyle = .overFullScreen
        self.present(reportViewController, animated: true, completion: nil)
    }
    
    func commentGotDeleteRequest(comment: Comment, answerToComment: Comment?) {
        self.deleteAlert(title: NSLocalizedString("delete_comment_alert_title", comment: "title"), message: NSLocalizedString("delete_comment_alert_message", comment: "cant be redeemed"), delete:  { (delete) in
            if delete {
                HandyHelper().deleteCommentInFirebase(comment: comment, answerToComment: answerToComment)
                self.commentTableView.deleteCommentFromTableView(comment: comment, answerToComment: answerToComment)
            }
        })
    }
    
    func toUserTapped(user: User) {
        performSegue(withIdentifier: "toUserSegue", sender: user)
    }
    
    func answerCommentTapped(comment: Comment) {
        if let answerView = self.floatingCommentView {
            answerView.addRecipientField(comment: comment)
        }
    }
    
}

//MARK: - MultiPictureCollectionView
extension PostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: MultiPictureCollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imageURLs.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = imageURLs[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? MultiImageCollectionCell {
            
            if image == defaultLinkString {
                cell.image = UIImage(named: "default-link")
            } else {
                cell.imageURL = image
                cell.layoutIfNeeded()
            }
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: MultiPictureCollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if post.type == .panorama {
            var height = post.mediaHeight
            if height > panoramaHeightMaximum {
                height = panoramaHeightMaximum
            }
            let width = post.mediaWidth
            
            let ratio = width/post.mediaHeight
            let newWidth = ratio*height
            
            let panoSize = CGSize(width: newWidth, height: height)
            return panoSize
        }
        let size = CGSize(width: imageCollectionView.frame.width, height: imageCollectionView.frame.height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = imageURLs[indexPath.item]
        
        let pinchVC = PinchToZoomViewController()
        pinchVC.imageURL = image
        pinchVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
}
