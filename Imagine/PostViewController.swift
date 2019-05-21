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


class PostViewController: UIViewController {
    
    var post = Post()
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
    var repostImageURL = ""
    
    let scrollView = UIScrollView()
    let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        showPost()
        showRepost()
        setupScrollView()
        setupViews()
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        dismissButton.layer.cornerRadius = dismissButton.bounds.size.width / 2
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.bounds.size.width / 2
        repostProfilePictureImageView.layer.cornerRadius = profilePictureImageView.bounds.size.width / 2

        
        let imageWidth = post.imageWidth
        let imageHeight = post.imageHeight
        
        if post.type == "picture" {
            if let url = URL(string: post.imageURL) {
                postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
            
            let ratio = imageWidth / imageHeight
            let contentWidth = self.contentView.frame.width - 10
            let newHeight = contentWidth / ratio
            
            postImageView.frame.size = CGSize(width: contentWidth, height: newHeight)
            postImageView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
            
        } else if post.type == "link" {
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
        } else if post.type == "repost" {
            if let url = URL(string: repostImageURL) {
                self.repostImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
            }
        }
    }
    
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
        contentView.addSubview(dismissButton)
        dismissButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25).isActive = true
        dismissButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        dismissButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        dismissButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        dismissButton.layoutIfNeeded() // Damit er auch rund wird
        
        contentView.addSubview(profilePictureImageView)
        profilePictureImageView.leadingAnchor.constraint(equalTo: dismissButton.trailingAnchor, constant: 25).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: dismissButton.centerYAnchor).isActive = true
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
        
        if post.type == "picture" {
            
            contentView.addSubview(postImageView)
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5).isActive = true
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 5).isActive = true
            postImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20).isActive = true
            postImageView.layoutIfNeeded() //?
            
            
            contentView.addSubview(descriptionLabel)
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
            descriptionLabel.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 15).isActive = true
            
        } else if post.type == "link" {
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
            
        } else if post.type == "repost" {
            
            contentView.addSubview(repostView)
            repostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
            repostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
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
            
        } else {    // Thought
            contentView.addSubview(descriptionLabel)
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15).isActive = true
            
        }
                
        contentView.addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 15).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        // !!!!! Am wichtigsten ist, dass ich unten angebe equalTo: contentView.bottomAnchor!!!!!!!
        // Wenn ich Trailing zu Trailing oder Bottom zu Bottom nehme, muss ich Minus Angaben nehmen :0!
    }
    
    
    
    let dismissButton : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .lightGray
        button.layer.masksToBounds = true
        button.setTitle("x", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        
        return button
    }()
    
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
        label.text = "Malte Schoppator"
        
        return label
    }()
    
    let createDateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "15.06.1996"
        
        return label
    }()
    
    let titleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.text = "Hier steht ein ganz einfallsreicher und witziger Titel des Posts!"
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label
    }()
    
    let postImageView : UIImageView = {
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
    
    let linkLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
        label.backgroundColor = .black
        label.layer.opacity = 0.5
        label.textColor = .white
        
        return label
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
        label.text = "Hier steht eine ganz Ausführliche Beschreibung für den Post laaaang und interessaaaaant!!"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        
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
        thanksButton.setTitle("Danke", for: .normal)
        thanksButton.backgroundColor = UIColor(red:0.13, green:0.31, blue:0.37, alpha:1.0)
        thanksButton.tintColor = UIColor.white
        
        let surpriseButton = DesignableButton()
        surpriseButton.setTitle("Surprise", for: .normal)
        surpriseButton.backgroundColor = UIColor(red:1.00, green:0.78, blue:0.66, alpha:1.0)
        surpriseButton.tintColor = UIColor.white
        
        let funnyButton = DesignableButton()
        funnyButton.setTitle("Funny", for: .normal)
        funnyButton.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
        funnyButton.tintColor = UIColor.white
        
        let moreButton = DesignableButton()
        moreButton.setTitle("Mehr", for: .normal)
        moreButton.backgroundColor = UIColor(red:0.72, green:0.84, blue:0.85, alpha:1.0)
        moreButton.tintColor = UIColor.white
        
        
        stackView.addArrangedSubview(thanksButton)
        stackView.addArrangedSubview(surpriseButton)
        stackView.addArrangedSubview(funnyButton)
        stackView.addArrangedSubview(moreButton)
        
        return stackView
    }()
    
    
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
        label.text = "Malte Schoppator"
        
        return label
    }()
    
    let repostCreateDateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = "15.06.1996"
        
        return label
    }()
    
    let repostTitleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.text = "Hier steht ein ganz einfallsreicher und witziger Titel des Posts!"
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
    
    
    func showPost() {
        titleLabel.text = post.title
        descriptionLabel.text = post.description
        createDateLabel.text = post.createTime
        nameLabel.text = post.originalPosterName
        
        if let url = URL(string: post.originalPosterImageURL) {
            profilePictureImageView.sd_setImage(with: url, completed: nil)
        }
        
    }
    
    func showRepost() {
        let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        // RepostDaten zuordnen
        if post.type == "repost" || post.type == "translation" {
            let repostRef = db.collection("Posts").document(post.OGRepostDocumentID)
            repostRef.getDocument(completion: { (document, err) in
                if let document = document {
                        if let docData = document.data() {

                            let repostCreateTime = docData["createTime"] as? Timestamp ?? Timestamp()
                            let repostTitle = docData["title"] as? String ?? "Können den Post nicht finden, tut uns Leid!"
                            let repostOriginalPosterUID = docData["originalPoster"] as? String ?? ""
                            self.repostImageURL = docData["imageURL"] as? String ?? ""  // Wird oben eingestellt
                            let repostImageHeight = docData["imageHeight"] as? CGFloat ?? 0
                            let repostImageWidth = docData["imageWidth"] as? CGFloat ?? 0
                            
                            let ratio = repostImageWidth / repostImageHeight
                            let contentWidth = self.contentView.frame.width - 10
                            let newHeight = contentWidth / ratio
                            
                            self.repostImageView.frame.size = CGSize(width: contentWidth, height: newHeight)
                            self.repostImageView.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
                        
                            // Timestamp umwandeln
                            let formatter = DateFormatter()
                            let date:Date = repostCreateTime.dateValue()
                            formatter.dateFormat = "dd MM yyyy HH:mm"
                            let stringDate = formatter.string(from: date)
                            
                            self.repostTitleLabel.text = repostTitle
                            self.repostCreateDateLabel.text = stringDate
                            
                            let repostUserRef = db.collection("Users").document(repostOriginalPosterUID)
                            
                            repostUserRef.getDocument(completion: { (doc, err) in
                                if let doc = doc {
                                    if let docData = doc.data() {
                                        let name = docData["name"] as? String ?? ""
                                        let surname = docData["surname"] as? String ?? ""
                                        let imageurl = docData["profilePictureURL"] as? String ?? ""
                                        
                                        self.repostNameLabel.text = "\(name) \(surname)"
                                        
                                        if let url = URL(string: imageurl) {
                                            self.repostProfilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                                        }
                                    }
                                }
                            })
                    }
                }
                if err != nil {
                    print("Wir haben einen Error beim Repost: \(err?.localizedDescription)")
                }
            })
        }
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
    
    @objc func dismissTapped() {
        dismiss(animated: true, completion: nil)
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? UserProfileViewController {
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
    }
    
}
