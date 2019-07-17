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
    
    var statusBar = false
    let db = Firestore.firestore()
    
    let handyHelper = HandyHelper()
    
    let scrollView = UIScrollView()
    let contentView = UIView()
    
    fileprivate var backUpViewHeight : NSLayoutConstraint?
    fileprivate var backUpButtonHeight : NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        savePostButton.tintColor = .black
        instantiateContainerView()
        
        
        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButton.tintColor = .green
            }
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
                        self.savePostButton.tintColor = .green
                    }
                }
            }
        }
        
    }
    
    func instantiateContainerView() {
        
        switch post.type {
        case .event:
            let vc = UserTableView(post: self.post)
            self.addChild(vc)
            vc.view.frame = CGRect(x: 0, y: 0, width: self.tableViewContainer.frame.size.width, height: self.tableViewContainer.frame.size.height)
            self.tableViewContainer.addSubview(vc.view)
            vc.didMove(toParent: self)
            
            let chatVC = PostCommentChatViewController(post: self.post)
            self.addChild(chatVC)
            chatVC.view.frame = CGRect(x: 0, y: 0, width: self.containerView.frame.size.width, height: self.containerView.frame.size.height)
            self.containerView.addSubview(chatVC.view)
            chatVC.didMove(toParent: self)
        default:
            let vc = PostCommentChatViewController(post: self.post)
            
            self.addChild(vc)
            vc.view.frame = CGRect(x: 0, y: 0, width: self.containerView.frame.size.width, height: self.containerView.frame.size.height)
            self.containerView.addSubview(vc.view)
            vc.didMove(toParent: self)
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupScrollView()
        setupViews()    // Die Anzeige des "nach oben" button + view ist verkehrt wenn man halb zurück wischt und los lässt, weil das hier dann wieder gecalled wird
        showPost()
        showRepost()
        
        
    }
    
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.bounds.size.width / 2
        repostProfilePictureImageView.layer.cornerRadius = profilePictureImageView.bounds.size.width / 2
        
        
        let imageWidth = post.imageWidth
        let imageHeight = post.imageHeight
        
        switch post.type {
        case .picture:
            if let url = URL(string: post.imageURL) {
                postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width - 10
            let newHeight = contentWidth / ratio
            
            postImageView.frame.size = CGSize(width: contentWidth, height: newHeight)
            postImageView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
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
            let imageWidth = post.event.imageWidth
            let imageHeight = post.event.imageHeight
            
            if let url = URL(string: post.event.imageURL) {
                postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width
            let newHeight = contentWidth / ratio
            
            postImageView.frame.size = CGSize(width: contentWidth, height: newHeight)
            postImageView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
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
            
            setUpEventUI()
        default:
            
            setUpUserUI()
            
            switch post.type {
            case .picture:
                setUpPictureUI()
                
                setUpCommentaryAndVoteUI()
            case .link:
                setUpLinkUI()
                
                setUpCommentaryAndVoteUI()
            case .repost:
                setUpRepostUI()
                
                setUpCommentaryAndVoteUI()
            case .thought:
                contentView.addSubview(descriptionLabel)
                descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
                descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15).isActive = true
                
                setUpCommentaryAndVoteUI()
            default:
                print("Nothing")
            }
        }
    }
    
    
    func setUpUserUI() {    // Name and Picture
        contentView.addSubview(profilePictureImageView)
        profilePictureImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 46).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 46).isActive = true
        profilePictureImageView.layoutIfNeeded() // Damit er auch rund wird
        
        contentView.addSubview(userButton)
        userButton.leadingAnchor.constraint(equalTo: profilePictureImageView.leadingAnchor).isActive = true
        userButton.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        userButton.widthAnchor.constraint(equalToConstant: profilePictureImageView.frame.width).isActive = true
        userButton.heightAnchor.constraint(equalToConstant: profilePictureImageView.frame.height).isActive = true
        userButton.layoutIfNeeded()
        
        contentView.addSubview(nameLabel)
        nameLabel.leadingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor, constant: 10).isActive = true
        nameLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        
        
        contentView.addSubview(createDateLabel)
        createDateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
        createDateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3).isActive = true
        
        
        contentView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        titleLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 15).isActive = true
        
        contentView.addSubview(savePostButton)
        savePostButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        savePostButton.topAnchor.constraint(equalTo: nameLabel.topAnchor).isActive = true
        savePostButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        savePostButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
    }
    
    func setUpCommentaryAndVoteUI() {
        // Bei allen ausser Event da
        
        contentView.addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 15).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        // stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        
        contentView.addSubview(containerView)   // For the chat-comment function
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true
        
        let viewHeight = self.view.frame.height
        
        containerView.heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        contentView.addSubview(backUpView)
        backUpView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        backUpView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        backUpView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        backUpViewHeight = backUpView.heightAnchor.constraint(equalToConstant: 0)
        backUpViewHeight!.isActive = true
        
        contentView.addSubview(self.backUpButton)
        backUpButton.leadingAnchor.constraint(equalTo: self.backUpView.leadingAnchor).isActive = true
        backUpButton.topAnchor.constraint(equalTo: self.backUpView.topAnchor, constant: 15).isActive = true
        backUpButton.widthAnchor.constraint(equalTo: self.backUpView.widthAnchor).isActive = true
        backUpButtonHeight = backUpButton.heightAnchor.constraint(equalToConstant: 0)
        backUpButtonHeight!.isActive = true
    }
    
    func setUpPictureUI() {
        contentView.addSubview(postImageView)
        postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5).isActive = true
        postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5).isActive = true
        postImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
        postImageView.layoutIfNeeded() //?
        
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 15).isActive = true
    }
    
    func setUpLinkUI() {
        contentView.addSubview(postImageView)
        postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0).isActive = true
        postImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        postImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
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
        
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 15).isActive = true
    }
    
    func setUpRepostUI() {
        contentView.addSubview(repostView)
        repostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5).isActive = true
        repostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5).isActive = true
        repostView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        repostView.layoutIfNeeded()
        
        repostView.addSubview(repostProfilePictureImageView)
        repostProfilePictureImageView.leadingAnchor.constraint(equalTo: repostView.leadingAnchor, constant: 10).isActive = true
        repostProfilePictureImageView.topAnchor.constraint(equalTo: repostView.topAnchor, constant: 10).isActive = true
        repostProfilePictureImageView.widthAnchor.constraint(equalToConstant: 46).isActive = true
        repostProfilePictureImageView.heightAnchor.constraint(equalToConstant: 46).isActive = true
        repostProfilePictureImageView.layoutIfNeeded() // Damit er auch rund wird
        
        repostView.addSubview(repostUserButton)
        repostUserButton.leadingAnchor.constraint(equalTo: repostProfilePictureImageView.leadingAnchor).isActive = true
        repostUserButton.topAnchor.constraint(equalTo: repostProfilePictureImageView.topAnchor).isActive = true
        repostUserButton.widthAnchor.constraint(equalToConstant: repostProfilePictureImageView.frame.width).isActive = true
        repostUserButton.heightAnchor.constraint(equalToConstant: repostProfilePictureImageView.frame.height).isActive = true
        repostUserButton.layoutIfNeeded()
        
        repostView.addSubview(repostNameLabel)
        repostNameLabel.leadingAnchor.constraint(equalTo: repostProfilePictureImageView.trailingAnchor, constant: 10).isActive = true
        repostNameLabel.topAnchor.constraint(equalTo: repostProfilePictureImageView.topAnchor).isActive = true
        
        
        repostView.addSubview(repostCreateDateLabel)
        repostCreateDateLabel.leadingAnchor.constraint(equalTo: repostNameLabel.leadingAnchor).isActive = true
        repostCreateDateLabel.topAnchor.constraint(equalTo: repostNameLabel.bottomAnchor, constant: 3).isActive = true
        
        
        repostView.addSubview(repostTitleLabel)
        repostTitleLabel.leadingAnchor.constraint(equalTo: repostView.leadingAnchor, constant: 15).isActive = true
        repostTitleLabel.trailingAnchor.constraint(equalTo: repostView.trailingAnchor, constant: -15).isActive = true
        repostTitleLabel.topAnchor.constraint(equalTo: repostProfilePictureImageView.bottomAnchor, constant: 15).isActive = true
        
        repostView.addSubview(repostImageView)
        repostImageView.leadingAnchor.constraint(equalTo: repostView.leadingAnchor).isActive = true
        repostImageView.trailingAnchor.constraint(equalTo: repostView.trailingAnchor).isActive = true
        repostImageView.topAnchor.constraint(equalTo: repostTitleLabel.bottomAnchor, constant: 10).isActive = true
        repostView.bottomAnchor.constraint(equalTo: repostImageView.bottomAnchor).isActive = true
        repostImageView.layoutIfNeeded() //?
        
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: repostView.bottomAnchor, constant: 15).isActive = true
    }
    
    func setUpEventUI() {
        contentView.addSubview(postImageView)
        postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        postImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        
        contentView.addSubview(titleLabel)
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 10).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 75).isActive = true
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 25)
        
        // Erstmal stackView zusammenbasteln
        firstStackView.addArrangedSubview(timeLabel)
        secondStackView.addArrangedSubview(locationLabel)
        eventStackView.addArrangedSubview(firstStackView)
        eventStackView.addArrangedSubview(secondStackView)
        
        contentView.addSubview(eventStackView)
        eventStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40).isActive = true
        eventStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40).isActive = true
        eventStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        eventStackView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        
        contentView.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: eventStackView.bottomAnchor, constant: 55).isActive = true
        descriptionLabel.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        descriptionLabel.layer.cornerRadius = 5
        
        
        let detailLabel = UILabel()
        contentView.addSubview(detailLabel)
        
        detailLabel.text = "Details:"
        detailLabel.font = UIFont.systemFont(ofSize: 17)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        detailLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -10).isActive = true
        
        
        contentView.addSubview(tableViewContainer)
        tableViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
        tableViewContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 50).isActive = true
        tableViewContainer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        
        let willBeThereLabel = UILabel()
        contentView.addSubview(willBeThereLabel)
        
        willBeThereLabel.text = "Bereits zugesagt:"
        willBeThereLabel.font = UIFont.systemFont(ofSize: 17)
        willBeThereLabel.translatesAutoresizingMaskIntoConstraints = false
        willBeThereLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        willBeThereLabel.bottomAnchor.constraint(equalTo: tableViewContainer.topAnchor, constant: -10).isActive = true
        
        contentView.addSubview(interestedButton)
        interestedButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30).isActive = true
        interestedButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30).isActive = true
        interestedButton.topAnchor.constraint(equalTo: tableViewContainer.bottomAnchor, constant: 15).isActive = true
        interestedButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        contentView.addSubview(containerView)   // For the chat-comment function
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: interestedButton.bottomAnchor).isActive = true
        let viewHeight = self.view.frame.height
        containerView.heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        contentView.addSubview(backUpView)
        backUpView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        backUpView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        backUpView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        backUpViewHeight = backUpView.heightAnchor.constraint(equalToConstant: 0)
        backUpViewHeight!.isActive = true
        
        contentView.addSubview(self.backUpButton)
        backUpButton.leadingAnchor.constraint(equalTo: self.backUpView.leadingAnchor).isActive = true
        backUpButton.topAnchor.constraint(equalTo: self.backUpView.topAnchor, constant: 15).isActive = true
        backUpButton.widthAnchor.constraint(equalTo: self.backUpView.widthAnchor).isActive = true
        backUpButtonHeight = backUpButton.heightAnchor.constraint(equalToConstant: 0)
        backUpButtonHeight!.isActive = true
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
        label.font = UIFont.systemFont(ofSize: 16)
        
        return label
    }()
    
    let createDateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        
        return label
    }()
    
    let titleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label
    }()
    
    lazy var postImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(postImageTapped)))
        let layer = imageView.layer
        layer.cornerRadius = 4
        layer.masksToBounds = true
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    let linkLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
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
        //        button.backgroundColor = UIColor(red:0.95, green:0.70, blue:0.24, alpha:1.0)
        button.setTitleColor(.black, for: .normal)
        
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
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        label.clipsToBounds = true
        
        return label
    }()
    
    let stackView : UIStackView = {
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis  = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.fill
        stackView.spacing   = 15.0
        stackView.sizeToFit()
        
        let thanksButton = DesignableButton()
        thanksButton.setImage(UIImage(named: "thanks"), for: .normal)
        thanksButton.backgroundColor = UIColor(red:0.13, green:0.31, blue:0.37, alpha:1.0)
        thanksButton.layer.cornerRadius = 4
        thanksButton.clipsToBounds = true
        
        let surpriseButton = DesignableButton()
        surpriseButton.setImage(UIImage(named: "wow"), for: .normal)
        surpriseButton.backgroundColor = UIColor(red:1.00, green:0.78, blue:0.66, alpha:1.0)
        surpriseButton.layer.cornerRadius = 4
        surpriseButton.clipsToBounds = true
        
        let funnyButton = DesignableButton()
        funnyButton.setImage(UIImage(named: "ha"), for: .normal)
        funnyButton.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
        funnyButton.layer.cornerRadius = 4
        funnyButton.clipsToBounds = true
        
        let moreButton = DesignableButton()
        moreButton.setImage(UIImage(named: "nice"), for: .normal)
        moreButton.backgroundColor = UIColor(red:0.72, green:0.84, blue:0.85, alpha:1.0)
        moreButton.layer.cornerRadius = 4
        moreButton.clipsToBounds = true
        
        
        stackView.addArrangedSubview(thanksButton)
        stackView.addArrangedSubview(surpriseButton)
        stackView.addArrangedSubview(funnyButton)
        stackView.addArrangedSubview(moreButton)
        
        return stackView
    }()
    
    
    
    // MARK: - Set Up Repost UI
    
    let repostProfilePictureImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    let repostUserButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        // anderer ... button.addTarget(self, action: #selector(userTapped), for: .touchUpInside)
        
        return button
    }()
    
    let repostNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        
        return label
    }()
    
    let repostCreateDateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        
        return label
    }()
    
    let repostTitleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
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
        layer.cornerRadius = 4
        layer.masksToBounds = true
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    // MARK: - Set up ChatUI
    
    let backUpView : UIVisualEffectView = {     // For the "backUpButton"
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        
        return blurEffectView
    }()
    
    let backUpButton : UIButton = {
        let button = UIButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.setTitleColor(.blue, for: .normal)
        
        button.setTitle(NSLocalizedString("back up", comment: "To go back up to the top out of the chat area"), for: .normal)
        button.addTarget(self, action: #selector(backUp), for: .touchUpInside)
        button.alpha = 0
        
        return button
    }()
    
    @objc func backUp() {
        scrollView.setContentOffset(.zero, animated: true)
        backUpButton.alpha = 0
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {     // When scrollView is at the Bottom
        
        if scrollView.isAtTop {
            UIView.animate(withDuration: 2, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                
                self.backUpViewHeight?.constant = 0
                self.backUpButtonHeight?.constant = 0
                self.backUpButton.alpha = 0
                
                self.view.layoutIfNeeded()
                
            }, completion: { (_) in
                
                
            })
        } else if scrollView.isAtBottom {
            
            UIView.animate(withDuration: 2, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveLinear, animations: {
                
                self.backUpButtonHeight?.constant = 35
                self.backUpViewHeight?.constant = 50
                self.backUpButton.alpha = 1
                
                self.view.layoutIfNeeded()
                
            }, completion: { (_) in
                
            })
        }
    }
    
    
    let containerView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        
        return view
    }()
    
    // MARK: - Set Up EventUI
    
    let tableViewContainer : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.cornerRadius = 5
        
        view.clipsToBounds = true
        
        return view
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 20)
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
        firstLabel.font = UIFont.systemFont(ofSize: 17)
        
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
        secondLabel.font = UIFont.systemFont(ofSize: 17)
        
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
    
    let interestedButton : UIButton = {
        let button = UIButton()
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red:0.61, green:0.91, blue:0.44, alpha:1.0)
        button.setTitleColor(.black, for: .normal)
        
        button.setTitle("Zusagen", for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        
        return button
    }()
    
    // MARK: - Functions
    
    @objc func postImageTapped() {
        let pinchVC = PinchToZoomViewController()
        
        pinchVC.post = self.post
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
                    self.savePostButton.tintColor = .green
                }
            }
        }
    }
    
    func showPost() {
        // Votes und so vom Post laden, wenn es aus der Suche kommt hat der noch nicht alles
        
        switch post.type {
        case .event:
            titleLabel.text = post.event.title
            timeLabel.text = "29.06.2019, 19:00 Uhr"
            locationLabel.text = post.event.location
            descriptionLabel.text = post.event.description
            
        default:
            titleLabel.text = post.title
            descriptionLabel.text = post.description
            createDateLabel.text = post.createTime
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
    
    func eventUserTapped(user: User) {
        performSegue(withIdentifier: "toUserSegue", sender: user.userUID)
    }
    
    @objc func userTapped() {
        if post.originalPosterUID != "" {
            performSegue(withIdentifier: "toUserSegue", sender: post.originalPosterUID)
        } else {
            print("Kein User zu finden!")
        }
    }
    
    @objc func linkTapped() {
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    
    @IBAction func moreTapped(_ sender: Any) {
        performSegue(withIdentifier: "reportSegue", sender: post)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? UserFeedTableViewController {
            if let OPUID = sender as? String {
                nextVC.userUID = OPUID
            } else {
                print("Irgendwas will der hier nicht übertragen")
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
    }
    
    
    
}



class UserTableView: UITableViewController {
    
    let post: Post?
    var users = [User]()
    
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
        
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textColor = .black
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        
        let postVC = PostViewController()
        postVC.eventUserTapped(user: user)
        
        //performSegue(withIdentifier: "toUserSegue", sender: user) WIrd nicht funktionieren, weil tableViewController nicht den gleichen Segue hat wie postviewcontroller
    }
    
    
}
