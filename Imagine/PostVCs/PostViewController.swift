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
import FirebaseFirestore
import FirebaseAuth
import YoutubePlayer_in_WKWebView

extension UIScrollView {
    
    var isAtTop: Bool {
        return contentOffset.y <= verticalOffsetForTop
    }
    
    var isAtBottom: Bool {
        return contentOffset.y >= verticalOffsetForBottom
    }
    
    var verticalOffsetForTop: CGFloat {
        let topInset = contentInset.top
        return -topInset
    }
    
    var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = bounds.height
        let scrollContentSizeHeight = contentSize.height
        let bottomInset = contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
    
}



class PostViewController: UIViewController, UIScrollViewDelegate {
    
    var post = Post()
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
    let db = Firestore.firestore()
    
    let handyHelper = HandyHelper()
    
    var ownPost = false
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    var centerX: NSLayoutConstraint?
    var distanceConstraint: NSLayoutConstraint?
    
    fileprivate var commentButtonTrailing: NSLayoutConstraint?
    fileprivate var backUpViewHeight : NSLayoutConstraint?
    fileprivate var backUpButtonHeight : NSLayoutConstraint?
    fileprivate var imageHeightConstraint : NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.activityStartAnimating()
        
        if #available(iOS 13.0, *) {
            savePostButton.tintColor = .label
        } else {
            savePostButton.tintColor = .black
        }
        scrollView.delegate = self
        
        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButton.tintColor = Constants.green
            }
        }
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(toCommentsTapped))
        swipeGesture.direction = .left
        commentView.addGestureRecognizer(swipeGesture)
        self.view.addGestureRecognizer(swipeGesture)
        
        self.view.addSubview(buttonLabel)
        setupViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        commentButton.alpha = 1
        
        // If you come back from PostCommentChatViewController
        if let trailingConstant = self.commentButtonTrailing {
            trailingConstant.constant = -15
        }
    }
    
    func setupViewController() {
        switch post.type {
        case .event:
            setupScrollView()
            setupViews()// Die Anzeige des "nach oben" button + view ist verkehrt wenn man halb zurück wischt und los lässt, weil das hier dann wieder gecalled wird
            showPost()
            instantiateContainerView()
        default:
            if post.user.name == "" {
                print("1")
                var toComments = false
                if post.toComments {    // Comes from the SideMenu NotifactionCenter
                    self.toCommentsTapped()
                    toComments = true
                }
                
                PostHelper().getPostsFromDocumentIDs(documentIDs: [post.documentID]) { (posts) in
                    if let post = posts?[0] {
                        print("1m5")
//                        post.getUser()    // Already done in getPostsFromDocumentIDs (9.10.19)
                        self.post = post
                        self.post.toComments = toComments
                        self.checkForData()
                    }
                }
            } else {
                self.loadPost()
            }
        }
    }
    
    func loadPost() {
        setupScrollView()
        setupViews()
        showPost()
        showRepost()
        instantiateContainerView()
    }
    
    
    
    var index = 0
    func checkForData() {
        print("Check for data")
        if index < 20 {
        if post.user.name != "" {
            print("2")
            self.setupViewController()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.index+=1
                if self.post.anonym {
                    print("Anonymous Post")
                    self.loadPost()
                } else {
                    self.checkForData()
                }
            }
        }
        } else {
            // Alert oder so
        }
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
    
    func instantiateContainerView() {
        
        switch post.type {
        case .event:
            let vc = UserTableView(post: self.post)
            vc.delegate = self
            
            self.addChild(vc)
            vc.view.frame = CGRect(x: 0, y: 0, width: self.tableViewContainer.frame.size.width, height: self.tableViewContainer.frame.size.height)
            self.tableViewContainer.addSubview(vc.view)
            vc.didMove(toParent: self)
            
        default:
          print("Whatever")
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("layout", post.type)
        
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.bounds.size.width / 2
        repostProfilePictureImageView.layer.cornerRadius = profilePictureImageView.bounds.size.width / 2
        print("Noch layout")
        let imageWidth = post.imageWidth
        let imageHeight = post.imageHeight
        
        print("Das ist der post.type: ", post.type)
        switch post.type {
        case .picture:
            if let url = URL(string: post.imageURL) {
                postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
            
            // No Post yet
            if imageWidth == 0 || imageHeight == 0 {
                print("no Post yet")
                return
            }
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width
            let newHeight = contentWidth / ratio
            
            
            postImageView.frame.size = CGSize(width: contentWidth, height: newHeight)
            
            // Otherwise there is an error, because somehow a 0 height is set somewhere for the picture
            if let _ = imageHeightConstraint {
                imageHeightConstraint!.constant = newHeight
                imageHeightConstraint!.isActive = true
            } else {
                imageHeightConstraint = postImageView.heightAnchor.constraint(equalToConstant: newHeight)
                imageHeightConstraint?.isActive = true
            }
            
        case .link:
            slp.preview(post.linkURL, onSuccess: { (result) in
                if let imageURL = result.image {
                    self.postImageView.contentMode = .scaleAspectFill
                    self.postImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                    
                    self.linkLabel.leadingAnchor.constraint(equalTo: self.postImageView.leadingAnchor).isActive = true
                    self.linkLabel.trailingAnchor.constraint(equalTo: self.postImageView.trailingAnchor).isActive = true
                    
                }
                if let linkSource = result.canonicalUrl {
                    self.linkLabel.text = linkSource
                }
            }) { (error) in
                print("We have an Error: \(error.localizedDescription)")
            }
        case .repost:
            if let repost = post.repost {
                if let url = URL(string: repost.imageURL) {
                    self.repostImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            }
        case .event:
            
            if let url = URL(string: post.event.imageURL) {
                postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
            
        default:
            print("Hier brauche ich noch was für nen Thought?")
        }
    }
    
    
    // MARK: - Setup Views
    
    func setupScrollView(){
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        contentView.layoutIfNeeded()        // Der hier sorgt dafür, dass das Bild auch beim zweiten Mal angezeigt wird. Da das Bild den Contentview braucht um die Höhe einzustellen. Das callt dann nämlich ViewDidLayoutSubviews
    }
    
    func setupViews(){
        switch post.type {
        case.event:
            
            setUpEventUI()  // No UserUI Setup in an Event
        default:
            
            setUpUserUI()
            
            switch post.type {
            case .picture:
                setUpPictureUI()
            case .link:
                setUpLinkUI()
                
            case .repost:
                setUpRepostUI()
                
            case .thought:
        
                addVoteAndDescriptionUI(topAnchorEqualTo: titleLabel.bottomAnchor)
            case .youTubeVideo:
                setUpYouTubeVideoUI()
                
            default:
                print("Nothing")
            }
        }
    }
    
    
    func setUpUserUI() {    // Name and Picture
        contentView.addSubview(profilePictureImageView)
        profilePictureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 46).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 46).isActive = true
        profilePictureImageView.layoutIfNeeded() // so it gets round
        
        contentView.addSubview(nameLabel)
        nameLabel.leadingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor, constant: 10).isActive = true
        nameLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        
        contentView.addSubview(userButton)
        userButton.leadingAnchor.constraint(equalTo: profilePictureImageView.leadingAnchor).isActive = true
        userButton.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        userButton.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor).isActive = true
        userButton.heightAnchor.constraint(equalToConstant: profilePictureImageView.frame.height).isActive = true
        userButton.layoutIfNeeded()
        
        contentView.addSubview(createDateLabel)
        createDateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
        createDateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3).isActive = true
        
        let titleLabelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
        
        contentView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        titleLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 1).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: titleLabelHeight).isActive = true 
        print("titleHeight: ", titleLabelHeight, post.title)
        
        contentView.addSubview(savePostButton)
        savePostButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        savePostButton.topAnchor.constraint(equalTo: nameLabel.topAnchor).isActive = true
        savePostButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        savePostButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        contentView.addSubview(translatePostButton)
        translatePostButton.trailingAnchor.constraint(equalTo: savePostButton.leadingAnchor, constant: -10).isActive = true
        translatePostButton.topAnchor.constraint(equalTo: nameLabel.topAnchor).isActive = true
        translatePostButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        translatePostButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
    }
    
    func addVoteAndDescriptionUI(topAnchorEqualTo: NSLayoutAnchor<NSLayoutYAxisAnchor>) {
        // Bei allen ausser Event da
        stackView.addArrangedSubview(thanksButton)
        stackView.addArrangedSubview(wowButton)
        stackView.addArrangedSubview(haButton)
        stackView.addArrangedSubview(niceButton)
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        stackView.addArrangedSubview(view)
        
        contentView.addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchorEqualTo, constant: 10).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        descriptionView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 10).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -10).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: 10).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: -10).isActive = true
        
        contentView.addSubview(descriptionView)
        descriptionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        descriptionView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10).isActive = true
//        descriptionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        commentView.addSubview(commentButton)
        commentButton.topAnchor.constraint(equalTo: commentView.topAnchor, constant: 10).isActive = true
        commentButtonTrailing = commentButton.trailingAnchor.constraint(equalTo: commentView.trailingAnchor, constant: -15)
            commentButtonTrailing!.isActive = true
        
        let voteButtonWidth = ((self.view.frame.width-(6*15))/5)
        let commentButtonWidth = voteButtonWidth*2+15
        commentButton.widthAnchor.constraint(equalToConstant: commentButtonWidth).isActive = true
        commentButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        contentView.addSubview(commentView)
        commentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        commentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        commentView.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 10).isActive = true
        commentView.heightAnchor.constraint(equalToConstant: 55).isActive = true
        commentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        
    }
    
    
    func setUpPictureUI() {
        contentView.addSubview(postImageView)
        postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        postImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1).isActive = true
        
        postImageView.layoutIfNeeded() //?
        
        addVoteAndDescriptionUI(topAnchorEqualTo: postImageView.bottomAnchor)
    }
    
    func setUpLinkUI() {
        contentView.addSubview(postImageView)
        postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        postImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1).isActive = true
        postImageView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        postImageView.layoutIfNeeded() //?
        
        contentView.addSubview(linkLabel)
        linkLabel.leadingAnchor.constraint(equalTo: postImageView.leadingAnchor).isActive = true
        linkLabel.trailingAnchor.constraint(equalTo: postImageView.trailingAnchor).isActive = true
        linkLabel.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor).isActive = true
        linkLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        contentView.addSubview(linkButton)
        linkButton.leadingAnchor.constraint(equalTo: postImageView.leadingAnchor).isActive = true
        linkButton.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor).isActive = true
        linkButton.widthAnchor.constraint(equalTo: postImageView.widthAnchor).isActive = true
        linkButton.heightAnchor.constraint(equalTo: postImageView.heightAnchor).isActive = true
        
        addVoteAndDescriptionUI(topAnchorEqualTo: postImageView.bottomAnchor)
    }
    
    func setUpYouTubeVideoUI() {
        contentView.addSubview(youTubeView)
        youTubeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        youTubeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        youTubeView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1).isActive = true
        youTubeView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        youTubeView.layoutIfNeeded() //?
        
        addVoteAndDescriptionUI(topAnchorEqualTo: youTubeView.bottomAnchor)
    }
    
    func setUpRepostUI() {
        contentView.addSubview(repostView)
        repostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        repostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        repostView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1).isActive = true
        repostView.layoutIfNeeded()
        
        repostView.addSubview(repostProfilePictureImageView)
        repostProfilePictureImageView.leadingAnchor.constraint(equalTo: repostView.leadingAnchor, constant: 10).isActive = true
        repostProfilePictureImageView.topAnchor.constraint(equalTo: repostView.topAnchor, constant: 10).isActive = true
        repostProfilePictureImageView.widthAnchor.constraint(equalToConstant: 46).isActive = true
        repostProfilePictureImageView.heightAnchor.constraint(equalToConstant: 46).isActive = true
        repostProfilePictureImageView.layoutIfNeeded() // Damit er auch rund wird
        
        repostView.addSubview(repostNameLabel)
        repostNameLabel.leadingAnchor.constraint(equalTo: repostProfilePictureImageView.trailingAnchor, constant: 10).isActive = true
        repostNameLabel.topAnchor.constraint(equalTo: repostProfilePictureImageView.topAnchor).isActive = true
        
        repostView.addSubview(repostCreateDateLabel)
        repostCreateDateLabel.leadingAnchor.constraint(equalTo: repostNameLabel.leadingAnchor).isActive = true
        repostCreateDateLabel.topAnchor.constraint(equalTo: repostNameLabel.bottomAnchor, constant: 3).isActive = true
        
        repostView.addSubview(repostTitleLabel)
        repostTitleLabel.leadingAnchor.constraint(equalTo: repostView.leadingAnchor, constant: 10).isActive = true
        repostTitleLabel.trailingAnchor.constraint(equalTo: repostView.trailingAnchor, constant: -10).isActive = true
        repostTitleLabel.topAnchor.constraint(equalTo: repostProfilePictureImageView.bottomAnchor, constant: 10).isActive = true
        
        repostView.addSubview(repostImageView)
        repostImageView.leadingAnchor.constraint(equalTo: repostView.leadingAnchor).isActive = true
        repostImageView.trailingAnchor.constraint(equalTo: repostView.trailingAnchor).isActive = true
        repostImageView.topAnchor.constraint(equalTo: repostTitleLabel.bottomAnchor, constant: 10).isActive = true
        repostView.bottomAnchor.constraint(equalTo: repostImageView.bottomAnchor).isActive = true
        repostImageView.layoutIfNeeded() //?
        
        repostView.addSubview(repostViewButton)
        repostViewButton.leadingAnchor.constraint(equalTo: repostView.leadingAnchor).isActive = true
        repostViewButton.topAnchor.constraint(equalTo: repostView.topAnchor).isActive = true
        repostViewButton.heightAnchor.constraint(equalTo: repostView.heightAnchor).isActive = true
        repostViewButton.widthAnchor.constraint(equalTo: repostView.widthAnchor).isActive = true
        
        repostView.addSubview(repostUserButton)
        repostUserButton.leadingAnchor.constraint(equalTo: repostProfilePictureImageView.leadingAnchor).isActive = true
        repostUserButton.topAnchor.constraint(equalTo: repostProfilePictureImageView.topAnchor).isActive = true
        repostUserButton.bottomAnchor.constraint(equalTo: repostProfilePictureImageView.bottomAnchor).isActive = true
        repostUserButton.trailingAnchor.constraint(equalTo: repostNameLabel.trailingAnchor).isActive = true
        
        addVoteAndDescriptionUI(topAnchorEqualTo: repostView.bottomAnchor)
    }
    
    func setUpEventUI() {
        contentView.addSubview(postImageView)
        postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        postImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        postImageView.heightAnchor.constraint(equalToConstant: 175).isActive = true
        
        contentView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 10).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 75).isActive = true
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "IBMPlexSans-Bold", size: 25)
        
        // Erstmal stackView zusammenbasteln
        firstStackView.addArrangedSubview(locationLabel)
        secondStackView.addArrangedSubview(timeLabel)
        eventStackView.addArrangedSubview(firstStackView)
        eventStackView.addArrangedSubview(secondStackView)
        
        contentView.addSubview(eventStackView)
        eventStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40).isActive = true
        eventStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40).isActive = true
        eventStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        eventStackView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        
        descriptionView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: descriptionView.leadingAnchor, constant: 10).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: descriptionView.trailingAnchor, constant: -10).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: descriptionView.topAnchor, constant: 10).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: -10).isActive = true
        
        contentView.addSubview(descriptionView)
        descriptionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        descriptionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        descriptionView.topAnchor.constraint(equalTo: eventStackView.bottomAnchor, constant: 55).isActive = true
        
        let detailLabel = UILabel()
        contentView.addSubview(detailLabel)
        
        detailLabel.text = "Beschreibung:"
        detailLabel.font = UIFont(name: "IBMPlexSans", size: 17)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        detailLabel.bottomAnchor.constraint(equalTo: descriptionView.topAnchor, constant: -10).isActive = true
        
        
        contentView.addSubview(tableViewContainer)
        tableViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -2).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 2).isActive = true
        tableViewContainer.topAnchor.constraint(equalTo: descriptionView.bottomAnchor, constant: 50).isActive = true
        tableViewContainer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        
        let willBeThereLabel = UILabel()
        contentView.addSubview(willBeThereLabel)
        
        willBeThereLabel.text = "Bereits zugesagt:"
        willBeThereLabel.font = UIFont(name: "IBMPlexSans", size: 17)
        willBeThereLabel.translatesAutoresizingMaskIntoConstraints = false
        willBeThereLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        willBeThereLabel.bottomAnchor.constraint(equalTo: tableViewContainer.topAnchor, constant: -5).isActive = true
        
        contentView.addSubview(interestedButton)
        interestedButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30).isActive = true
        interestedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30).isActive = true
        interestedButton.topAnchor.constraint(equalTo: tableViewContainer.bottomAnchor, constant: 15).isActive = true
        interestedButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
//        interestedButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        
        commentView.addSubview(commentButton)
        commentButton.topAnchor.constraint(equalTo: commentView.topAnchor, constant: 10).isActive = true
        commentButtonTrailing = commentButton.trailingAnchor.constraint(equalTo: commentView.trailingAnchor, constant: -10)
        commentButtonTrailing!.isActive = true
        commentButton.widthAnchor.constraint(equalToConstant: 125).isActive = true
        commentButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        contentView.addSubview(commentView)
        commentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        commentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        commentView.topAnchor.constraint(equalTo: interestedButton.bottomAnchor, constant: 10).isActive = true
        commentView.heightAnchor.constraint(equalToConstant: 55).isActive = true
        commentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
    }
    
    // MARK: - Setup UI
    
    let repostView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.0)
        view.layer.cornerRadius = 5
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1
        view.clipsToBounds = true
        
        return view
    }()
    
    let profilePictureImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let userButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(userTapped), for: .touchUpInside)
        
        return button
    }()

    let nameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 15)
        
        return label
    }()
    
    let createDateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Light", size: 11)
        
        return label
    }()
//    mit button zu kommentaren um layoutissue in den griff zu bekommen
    let titleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 20)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.minimumScaleFactor = 0.8
        label.sizeToFit()
        
        return label
    }()
    
    lazy var postImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default")
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(postImageTapped)))
        let layer = imageView.layer
        layer.cornerRadius = 1
        layer.masksToBounds = true
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    let youTubeView: WKYTPlayerView = {
        let ytv = WKYTPlayerView()
        ytv.translatesAutoresizingMaskIntoConstraints = false
        
        return ytv
    }()
    
    let linkLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 15)
        label.backgroundColor = .black
        label.layer.opacity = 0.5
        label.textColor = .white
        
        return label
    }()
    
    let savePostButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(savePostTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "save"), for: .normal)
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        
        return button
    }()
    
    let translatePostButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(translatePostTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "globe"), for: .normal)
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
        } else {
            button.setTitleColor(.black, for: .normal)
        }
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        
        return button
    }()
    
    let linkButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(linkTapped), for: .touchUpInside)
        
        return button
    }()
    
    let descriptionLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Regular", size: 20)
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.left
        label.sizeToFit()
        label.clipsToBounds = true
        
        return label
    }()
    
    let descriptionView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemBackground
        } else {
            view.backgroundColor = UIColor(red:1.00, green:0.93, blue:0.84, alpha:1.0)
        }
        
        return view
    }()
    
    let commentButton : DesignableButton = {
        let commentButton = DesignableButton()
        commentButton.translatesAutoresizingMaskIntoConstraints = false
        commentButton.addTarget(self, action: #selector(toCommentsTapped), for: .touchUpInside)
        commentButton.setTitle("Kommentare", for: .normal)
        commentButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
        commentButton.layer.cornerRadius = 4
        commentButton.backgroundColor = UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0)
        
        return commentButton
    }()
    
    
    let commentView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    let thanksButton : DesignableButton = {
        let thanksButton = DesignableButton()
        thanksButton.setImage(UIImage(named: "thanks"), for: .normal)
        thanksButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 14)
        if #available(iOS 13.0, *) {
            thanksButton.setTitleColor(.label, for: .normal)
        } else {
            thanksButton.setTitleColor(.black, for: .normal)
        }

        if #available(iOS 13.0, *) {
            thanksButton.tintColor = .label
        } else {
            thanksButton.tintColor = .black
        }
//        thanksButton.backgroundColor = Constants.thanksColor
        thanksButton.layer.borderColor = Constants.thanksColor.cgColor
        thanksButton.layer.borderWidth = 1.5
        thanksButton.layer.cornerRadius = 4
        thanksButton.clipsToBounds = true
        thanksButton.addTarget(self, action: #selector(thanksTapped), for: .touchUpInside)
        
        return thanksButton
    }()
    
    let wowButton: DesignableButton = {
        let wowButton = DesignableButton()
        wowButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 14)
        if #available(iOS 13.0, *) {
            wowButton.setTitleColor(.label, for: .normal)
        } else {
            wowButton.setTitleColor(.black, for: .normal)
        }
        if #available(iOS 13.0, *) {
            wowButton.tintColor = .label
        } else {
            wowButton.tintColor = .black
        }
        wowButton.setImage(UIImage(named: "wow"), for: .normal)
//        wowButton.backgroundColor = Constants.wowColor
        wowButton.layer.borderColor = Constants.wowColor.cgColor
        wowButton.layer.borderWidth = 1.5
        wowButton.layer.cornerRadius = 4
        wowButton.clipsToBounds = true
        wowButton.addTarget(self, action: #selector(wowTapped), for: .touchUpInside)
        
        return wowButton
    }()
    
    let haButton: DesignableButton = {
        let haButton = DesignableButton()
        if #available(iOS 13.0, *) {
            haButton.setTitleColor(.label, for: .normal)
        } else {
            haButton.setTitleColor(.black, for: .normal)
        }
        if #available(iOS 13.0, *) {
            haButton.tintColor = .label
        } else {
            haButton.tintColor = .black
        }
        haButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 14)
        haButton.setImage(UIImage(named: "ha"), for: .normal)
//        haButton.backgroundColor = Constants.haColor
        haButton.layer.borderColor = Constants.haColor.cgColor
        haButton.layer.borderWidth = 1.5
        haButton.layer.cornerRadius = 4
        haButton.clipsToBounds = true
        haButton.addTarget(self, action: #selector(haTapped), for: .touchUpInside)
        
        return haButton
    }()
    
    let niceButton: DesignableButton = {
        let niceButton = DesignableButton()
        if #available(iOS 13.0, *) {
            niceButton.setTitleColor(.label, for: .normal)
        } else {
            niceButton.setTitleColor(.black, for: .normal)
        }
        if #available(iOS 13.0, *) {
            niceButton.tintColor = .label
        } else {
            niceButton.tintColor = .black
        }
        niceButton.setImage(UIImage(named: "nice"), for: .normal)
        niceButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 14)
//        niceButton.backgroundColor = Constants.niceColor
        niceButton.layer.borderColor = Constants.niceColor.cgColor
        niceButton.layer.borderWidth = 1.5
        niceButton.layer.cornerRadius = 4
        niceButton.clipsToBounds = true
        niceButton.addTarget(self, action: #selector(niceTapped), for: .touchUpInside)
        
        return niceButton
    }()
    
    let shareButton: DesignableButton = {
        let shareButton = DesignableButton()
        shareButton.setTitle("Share", for: .normal)
        shareButton.backgroundColor = UIColor(red:0.47, green:0.68, blue:0.95, alpha:1.0)
        shareButton.layer.cornerRadius = 4
        shareButton.clipsToBounds = true
        shareButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 14)
        
        return shareButton
    }()
    
    let stackView : UIStackView = {
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.fill
        stackView.spacing = 15.0
        stackView.sizeToFit()
        
        return stackView
    }()
    
    
    
    // MARK: - Set Up Repost UI
    
    let repostProfilePictureImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(postImageTapped)))
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let repostUserButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(repostUserTapped), for: .touchUpInside)
        
        return button
    }()
    
    let repostViewButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(repostViewTapped), for: .touchUpInside)
        
        return button
    }()
    
    let repostNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 16)
        
        return label
    }()
    
    let repostCreateDateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 10)
        
        return label
    }()
    
    let repostTitleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 20)
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label
    }()
    
    let repostImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.contentMode = .scaleAspectFit
        let layer = imageView.layer
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(postImageTapped)))
        layer.cornerRadius = 4
        layer.masksToBounds = true
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.isAtTop {
//            UIView.animate(withDuration: 2, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
//
//                self.backUpViewHeight?.constant = 0
//                self.backUpButtonHeight?.constant = 0
//                self.backUpButton.alpha = 0
//
//                self.view.layoutIfNeeded()
//
//            }, completion: { (_) in
//
//
//            })
//        } else if scrollView.isAtBottom {
//
//            UIView.animate(withDuration: 2, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveLinear, animations: {
//
//                self.backUpButtonHeight?.constant = 35
//                self.backUpViewHeight?.constant = 50
//                self.backUpButton.alpha = 1
//
//                self.view.layoutIfNeeded()
//
//            }, completion: { (_) in
//
//            })
//        }
//    }
    
    // MARK: - Set Up EventUI
    
    let tableViewContainer : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
        
        view.clipsToBounds = true
        
        return view
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont(name: "IBMPlexSans-Bold", size: 20)
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont(name: "IBMPlexSans-Bold", size: 20)
        return label
    }()
    
    let firstStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        let firstLabel = UILabel()
        firstLabel.translatesAutoresizingMaskIntoConstraints = false
        firstLabel.widthAnchor.constraint(equalToConstant: 75).isActive = true
        firstLabel.textAlignment = .left
        firstLabel.text = "Wo:"
        firstLabel.font = UIFont(name: "IBMPlexSans", size: 17)
        
        stackView.addArrangedSubview(firstLabel)
        
        return stackView
    }()
    
    let secondStackView: UIStackView = {
        let stackView = UIStackView()
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        let secondLabel = UILabel()
        secondLabel.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.widthAnchor.constraint(equalToConstant: 75).isActive = true
        secondLabel.textAlignment = .left
        secondLabel.text = "Wann:"
        secondLabel.font = UIFont(name: "IBMPlexSans", size: 17)
        
        stackView.addArrangedSubview(secondLabel)
        
        return stackView
    }()
    let eventStackView : UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.fill
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        return stackView
    }()
    
    let interestedButton : DesignableButton = {
        let button = DesignableButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red:0.61, green:0.91, blue:0.44, alpha:1.0)
        button.setTitleColor(.black, for: .normal)
        
        button.setTitle("Zusagen", for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        
        return button
    }()
    
    let buttonLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        //        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        label.alpha = 0.8
        
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 2
        label.layer.shadowOffset = CGSize(width: 0, height: 11)
        label.layer.masksToBounds = false
        
        return label
    }()
    
    // MARK: - Functions
    
    func showPost() {
        
        if let user = Auth.auth().currentUser {
            if user.uid == post.originalPosterUID {
                self.ownPost = true
                
                self.thanksButton.setImage(nil, for: .normal)
                self.thanksButton.setTitle(String(post.votes.thanks), for: .normal)
                self.thanksButton.layer.borderWidth = 0
                self.thanksButton.backgroundColor = Constants.thanksColor
                self.thanksButton.setTitleColor(.white, for: .normal)
                self.wowButton.setImage(nil, for: .normal)
                self.wowButton.setTitle(String(post.votes.wow), for: .normal)
                self.wowButton.layer.borderWidth = 0
                self.wowButton.backgroundColor = Constants.wowColor
                self.wowButton.setTitleColor(.white, for: .normal)
                self.haButton.setImage(nil, for: .normal)
                self.haButton.setTitle(String(post.votes.ha), for: .normal)
                self.haButton.layer.borderWidth = 0
                self.haButton.backgroundColor = Constants.haColor
                self.haButton.setTitleColor(.white, for: .normal)
                self.niceButton.setImage(nil, for: .normal)
                self.niceButton.setTitle(String(post.votes.nice), for: .normal)
                self.niceButton.layer.borderWidth = 0
                self.niceButton.backgroundColor = Constants.niceColor
                self.niceButton.setTitleColor(.white, for: .normal)
            }
        }
        
        self.view.activityStopAnimating()
        
        let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
        let descriptionText = post.description.replacingOccurrences(of: "\\n", with: newLineString)
        
        switch post.type {
        case .event:
            titleLabel.text = post.event.title
            timeLabel.text = post.event.time
            locationLabel.text = post.event.location
            
            let eventDescription = post.event.description.replacingOccurrences(of: "\\n", with: newLineString)
            if eventDescription == "" {
                self.descriptionView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            } else {
                descriptionLabel.text = eventDescription
            }
        case .youTubeVideo:
            titleLabel.text = post.title
            descriptionLabel.text = descriptionText
            createDateLabel.text = post.createTime
            if let youTubeID = post.linkURL.youtubeID {
                youTubeView.load(withVideoId: youTubeID)
            }
            
            self.setUser()
            
            if descriptionText == "" {
                self.descriptionView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            } else {
                descriptionLabel.text = descriptionText
            }
        default:
            titleLabel.text = post.title
            
            createDateLabel.text = post.createTime
            
            self.setUser()
            
            if descriptionText == "" {
                self.descriptionView.heightAnchor.constraint(equalToConstant: 0).isActive = true
            } else {
                descriptionLabel.text = descriptionText
            }
        }
        
    }
    
    func setUser() {
        if self.post.anonym {
            profilePictureImageView.image = UIImage(named: "default-user")
            nameLabel.text = Constants.strings.anonymPosterName
        } else {
            nameLabel.text = "\(post.user.name) \(post.user.surname)"
            
            if let url = URL(string: post.user.imageURL) {
                profilePictureImageView.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    func showRepost() {
        if let repost = post.repost {
            
            let ratio = repost.imageWidth / repost.imageHeight
            let contentWidth = self.contentView.frame.width - 10
            let newHeight = contentWidth / ratio
            
            self.repostImageView.frame.size = CGSize(width: contentWidth, height: newHeight)
            self.repostImageView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
            
            self.repostTitleLabel.text = repost.title
            self.repostCreateDateLabel.text = repost.createTime
            self.repostNameLabel.text = "\(repost.user.name) \(repost.user.surname)"
            
            if let url = URL(string: repost.user.imageURL) {
                self.repostProfilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
        }
    }
    
    @objc func postImageTapped() {
        let pinchVC = PinchToZoomViewController()
        
        switch post.type {
        case .repost:
            pinchVC.post = self.post.repost!
        default:
            pinchVC.post = self.post
        }
        
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
    
    
    @objc func savePostTapped() {
        if let user = Auth.auth().currentUser {
            let ref = db.collection("Users").document(user.uid).collection("saved").document()
            
            let data: [String:Any] = ["createTime": Timestamp(date: Date()), "documentID": post.documentID]
            
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
    
    @objc func translatePostTapped() {
        performSegue(withIdentifier: "toTranslateSegue", sender: post)
    }
    
    
    
    func eventUserTapped(user: User) {
        self.performSegue(withIdentifier: "toUserSegue", sender: user)
    }
    
    @objc func repostViewTapped() {
        if let repost = post.repost {
            let postVC = self.storyboard?.instantiateViewController(withIdentifier: "PostVC") as! PostViewController
            postVC.post = repost
            self.navigationController?.pushViewController(postVC, animated: true)
        }
    }
    
    @objc func repostUserTapped() {
        if let repost = post.repost {
            if repost.originalPosterUID != "" {
                if repost.anonym {
                    performSegue(withIdentifier: "toUserSegue", sender: repost.user)
                }
            } else {
                print("no user to find")
            }
        }
    }
    
    @objc func userTapped() {
        if post.originalPosterUID != "" {
            if !post.anonym {
                performSegue(withIdentifier: "toUserSegue", sender: post.user)
            }
        } else {
            print("Kein User zu finden!")
        }
    }
    
    @objc func linkTapped() {
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    @objc func thanksTapped() {
        updatePost(button: .thanks)
    }
    
    @objc func wowTapped() {
        updatePost(button: .wow)
    }
    
    @objc func haTapped() {
        updatePost(button: .ha)
    }
    
    @objc func niceTapped() {
        updatePost(button: .nice)
    }
    
    func updatePost(button: VoteButton) {
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
            showButtonText(post: self.post, button: desButton)
            //To-Do: Update number on Button and show animation
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func showButtonText(post: Post, button: DesignableButton) {
        buttonLabel.alpha = 1
        button.titleLabel?.textColor = .black
        button.setTitleColor(.black, for: .normal)
        
        if let _ = centerX {
            centerX!.isActive = false
            //            centerX = nil
            
            distanceConstraint!.isActive = false
        }
        
        centerX = buttonLabel.centerXAnchor.constraint(equalTo: button.centerXAnchor)
        centerX!.priority = UILayoutPriority(rawValue: 250)
        centerX!.isActive = true
        
        distanceConstraint = buttonLabel.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -5)
        distanceConstraint!.priority = UILayoutPriority(rawValue: 250)
        distanceConstraint!.isActive = true
        self.view.layoutIfNeeded()
        
        var title = String(post.votes.thanks)
        
        switch button {
        case thanksButton:
            buttonLabel.text = "danke"
        case wowButton:
            buttonLabel.text = "wow"
            title = String(post.votes.wow)
        case haButton:
            buttonLabel.text = "ha"
            title = String(post.votes.ha)
        case niceButton:
            buttonLabel.text = "nice"
            title = String(post.votes.nice)
        default:
            buttonLabel.text = "so nicht"
        }
        
        distanceConstraint!.constant = -30
        
        UIView.animate(withDuration: 1.5) {
            self.view.layoutIfNeeded()
            self.buttonLabel.alpha = 0
        }
        
        button.setImage(nil, for: .normal)
        button.setTitle(title, for: .normal)
    }
    
    @IBAction func moreTapped(_ sender: Any) {
        performSegue(withIdentifier: "reportSegue", sender: post)
    }
    
    @objc func toCommentsTapped() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Jetzt ist es toComments?: ", self.post.toComments)
            let viewController = PostCommentChatViewController(post: self.post)
            UIView.transition(with: self.navigationController!.view, duration: 0.5, options: .transitionFlipFromRight, animations: {
                self.navigationController?.pushViewController(viewController, animated: true)
            }, completion: nil)
        }
        
        if let commentConstant = self.commentButtonTrailing {
            commentConstant.constant = -250
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.commentButton.alpha = 0
        }) { (_) in
        }
        
    }
    
    @objc func writeCommentTapped() {
        
    }
    
    func goToEventUser(user: User) {
        performSegue(withIdentifier: "toUserSegue", sender: user)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
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
                if let reportVC = segue.destination as? MeldenViewController {
                    reportVC.post = chosenPost
                    
                }
            }
        }
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

extension PostViewController: EventUserDelegate {
    func goToUser(user: User) {
        performSegue(withIdentifier: "toUserSegue", sender: user)
    }
}

protocol EventUserDelegate {
    func goToUser(user: User)
}

class UserTableView: UITableViewController {
    
    let post: Post?
    var users = [User]()
    
    var delegate:EventUserDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        getUsers()
    }
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getUsers() {
        if let post = post {
            
            HandyHelper().getUsers(userList: post.event.participants) { (users) in
                self.users = users
                
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        
        let cell = UITableViewCell()
        
        let iconImageView = UIImageView()
        cell.addSubview(iconImageView)
        
        if let url = URL(string: user.imageURL) {
            iconImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
        } else {
            iconImageView.image = UIImage(named: "default-user")
        }
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFill
        
        iconImageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10).isActive = true
        iconImageView.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -5).isActive = true
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        iconImageView.layer.cornerRadius = 15
        iconImageView.clipsToBounds = true
        
        let nameLabel = UILabel()
        cell.addSubview(nameLabel)
        
        nameLabel.text = "\(user.name) \(user.surname)"
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 15).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -5).isActive = true
        
        nameLabel.font = UIFont(name: "IBMPlexSans", size: 15)
        nameLabel.textColor = .black
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        
        delegate?.goToUser(user: user)
    }
    
    
}
