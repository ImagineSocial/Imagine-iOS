//
//  UserFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import AVKit
import WebKit

// This enum represents the different states, when accessing the UserFeedTableVC
enum AccessState{
    case ownProfileWithEditing
    case ownProfile
    case otherUser
    case friendOfCurrentUser
    case blockedToInteract
}

enum SocialMediaType {
    case patreon
    case youTube
    case instagram
    case twitter
    case songwhip
}

class SocialMediaObject {
    var type: SocialMediaType
    var link: String
    var description: String?
    
    init(type: SocialMediaType, link: String, description: String?) {
        self.type = type
        self.link = link
        self.description = description
    }
}

protocol LogOutDelegate {
    /// Triggered when the User logges themselve out. Otherwise they would get notified after they logged themself in and a new user could not get a new notificationListener
    func deleteListener()
}

class UserFeedTableViewController: BaseFeedTableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var addAsFriendButton: DesignableButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var profilePictureButton: DesignableButton!
    @IBOutlet weak var blogPostButton: DesignableButton!
    @IBOutlet weak var chatWithUserButton: DesignableButton!
    @IBOutlet weak var moreButton: DesignableButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var totalPostCountLabel: UILabel!
    @IBOutlet weak var firstBadgeImageView: UIImageView!
    @IBOutlet weak var secondBadgeImageView: UIImageView!
    @IBOutlet weak var interactionBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var settingButton: UIButton!
    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    
    //socialMediaStuff
    @IBOutlet weak var socialMediaInteractionStackView: UIStackView!
    @IBOutlet weak var socialMediaInteractionBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var socialMediaDescriptionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var socialMediaDescriptionLabel: UILabel!
    @IBOutlet weak var socialMediaDescriptionButton: DesignableButton!
    @IBOutlet weak var socialMediaDescriptionImageView: UIImageView!
    
    
    /* You have to set currentState and userOfProfile when you call this VC - Couldnt get the init to work */
    
    var imagePicker = UIImagePickerController()
    var imageURL = ""
    var selectedImageFromPicker = UIImage(named: "default-user")
    var userOfProfile:User?
    
    var currentState:AccessState?
    
    var socialMediaObjects: [SocialMediaObject]?
    
    var delegate: LogOutDelegate?
    
    let defaultStatusText = NSLocalizedString("user_status_default_text", comment: "Here is your status text")
    var tableViewHeaderHeight: CGFloat = 240
    let socialMediaStackViewHeight: CGFloat = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = 8
        layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            layer.borderColor = UIColor.lightGray.cgColor
        }
        
        if #available(iOS 13.0, *) {
            chatWithUserButton.layer.borderColor = UIColor.tertiaryLabel.cgColor
            addAsFriendButton.layer.borderColor = UIColor.tertiaryLabel.cgColor
        } else {
            chatWithUserButton.layer.borderColor = UIColor.lightGray.cgColor
            addAsFriendButton.layer.borderColor = UIColor.lightGray.cgColor
        }
        chatWithUserButton.layer.borderWidth = 0.75
        addAsFriendButton.layer.borderWidth = 0.75
        
        setCurrentState()   // check if blocked or own profile
        setBarButtonItem()
        
        imagePicker.delegate = self
        
        let profileInfoShown = UserDefaults.standard.bool(forKey: "userFeedInfo")
        if !profileInfoShown {
            showInfoView()
        }
    }
    
    func showInfoView() {
        let upperHeight = UIApplication.shared.statusBarFrame.height +
              self.navigationController!.navigationBar.frame.height
        let height = upperHeight+40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .userFeed
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(popUpView)
        }
        
        UIView.animate(withDuration: 0.5) {
            popUpView.alpha = 1
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.updateHeaderViewHeight()
    }
    
    func setCurrentState() {
        
        //setPlaceholder
        var index = 0
        
        while index <= 2 {
            let post = Post()
            if index == 1 {
                post.type = .picture
            } else {
                post.type = .thought
            }
            self.posts.append(post)
            index+=1
        }
        self.tableView.reloadData()
        
        //Check if allowed to load
        if let user = Auth.auth().currentUser {
            if let profileUser = userOfProfile {
                if let blocked = profileUser.blocked {
                    for id in blocked {
                        if id == user.uid {
                            self.currentState = .blockedToInteract
                            
                            // remove ActivityIndicator
                            self.view.activityStopAnimating()
                            
                            print("blocked")
                        }
                    }   // Get User after checked
                    self.getUserDetails()
                } else {    // Nobody blocked yet
                    self.getUserDetails()
                }
                
            } else {    // From side menu
               getUserDetails()
            }
        } else {    // Nobody logged in
            getUserDetails()
        }
    }
    
    func getUserDetails() {
        
        guard let state = currentState else {
            
            print("Hier ist kein State")
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        switch state {
        case .ownProfile:
            self.setOwnProfile()
            self.noPostsType = .userProfile
        case .ownProfileWithEditing:
            self.isOwnProfile = true
            self.settingButton.isHidden = false
            self.noPostsType = .ownProfile
            self.setOwnProfile()
        case .otherUser:
            self.checkIfAlreadyFriends()
            self.setUserProfile()
            self.noPostsType = .userProfile
        case .friendOfCurrentUser:
            self.addAsFriendButton.setTitle(NSLocalizedString("remove_as_friend_label", comment: "remove as friend"), for: .normal)
            self.setUserProfile()
            self.noPostsType = .userProfile
        case .blockedToInteract:
            self.profilePictureImageView.image = UIImage(named: "default-user")
            if let currentUser = userOfProfile {
                self.nameLabel.text = currentUser.displayName  //Blocked means not befriended, so it shows the username
            }
        }
    }
    
    override func getPosts(getMore: Bool) {
        
        guard let currentState = currentState else { return }
        
        switch currentState {
        case .blockedToInteract:
            self.refreshControl?.endRefreshing()
            print("no posts will get fetched cause blocked")
        default:
            if isConnected() {
                
                if let user = userOfProfile {
                    
                    self.view.activityStartAnimating()
                    
                    firestoreRequest.getPostList(getMore: getMore, whichPostList: .postsFromUser, userUID: user.userUID) { (posts, initialFetch)  in
                        
                        guard let posts = posts else {
                            print("No more Posts")
                            self.view.activityStopAnimating()
                            
                            return
                        }
                        
                        if initialFetch {   // Get the first batch of posts
                            self.posts.removeAll()  //Remove the placeholder
                            self.posts = posts
                            self.tableView.reloadData()
                            self.fetchesPosts = false
                            
                            let count = self.firestoreRequest.getTotalCount()
                            self.totalPostCountLabel.text = String(count)
                            
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
                        }
                        
                        // remove ActivityIndicator incl. backgroundView
                        self.view.activityStopAnimating()
                    }
                }
            } else {
                fetchRequested = true
            }
        }
    }
    
    
    // MARK: - SetUI
    
    func setBarButtonItem() {
        
        guard let state = currentState else { return }
        
        switch state {
        case .ownProfileWithEditing:
            let LogOutButton = DesignableButton(type: .custom)
            LogOutButton.setTitle("Log-Out", for: .normal)
            LogOutButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 18)
            LogOutButton.setTitleColor(UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0), for: .normal)
            LogOutButton.addTarget(self, action: #selector(self.logOutTapped), for: .touchUpInside)
            LogOutButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
            LogOutButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            
            let rightBarButton = UIBarButtonItem(customView: LogOutButton)
            self.navigationItem.rightBarButtonItem = rightBarButton
        case .ownProfile:
            print("Here will nothing happen")
            
        // You can block someone who blocked you for now
        default:
            self.moreButton.isHidden = false
        }
    }
    
    func setOwnProfile() {
        
        chatWithUserButton.isHidden = true // Not possible to message yourself
        addAsFriendButton.isHidden = true
        profilePictureButton.isEnabled = true
        
        if let user = Auth.auth().currentUser {
            let currentUser = User()
            currentUser.userUID = user.uid
            
            let ref = db.collection("Users").document(user.uid)
            ref.getDocument { (doc, err) in
                if let err = err {
                    print("We have an error: \(err.localizedDescription)")
                } else {
                    if let doc = doc {
                        if let docData = doc.data() {
                            var medias = [SocialMediaObject]()
                            
                            if let instagramLink = docData["instagramLink"] as? String {
                                let description = docData["instagramDescription"] as? String
                                let media = SocialMediaObject(type: .instagram, link: instagramLink, description: description)
                                medias.append(media)
                            }
                            if let patreonLink = docData["patreonLink"] as? String {
                                let description = docData["patreonDescription"] as? String
                                let media = SocialMediaObject(type: .patreon, link: patreonLink, description: description)
                                medias.append(media)
                            }
                            if let youTubeLink = docData["youTubeLink"] as? String {
                                let description = docData["youTubeDescription"] as? String
                                let media = SocialMediaObject(type: .youTube, link: youTubeLink, description: description)
                                medias.append(media)
                            }
                            if let twitterLink = docData["twitterLink"] as? String {
                                let description = docData["twitterDescription"] as? String
                                let media = SocialMediaObject(type: .twitter, link: twitterLink, description: description)
                                medias.append(media)
                            }
                            if let songwhipLink = docData["songwhipLink"] as? String {
                                let description = docData["songwhipDescription"] as? String
                                let media = SocialMediaObject(type: .songwhip, link: songwhipLink, description: description)
                                medias.append(media)
                            }
                            
                            if medias.count != 0 {
                                self.socialMediaObjects = medias
                                self.setSocialMediaBar(socialMediaObjects: medias)
                            }
                            if let statusQuote = docData["statusText"] as? String {
                                if statusQuote != "" {
                                    self.statusLabel.text = statusQuote
                                    currentUser.statusQuote = statusQuote
                                } else {
                                    self.statusLabel.text = self.defaultStatusText
                                }
                            } else {
                                self.statusLabel.text = self.defaultStatusText
                            }
                            
                            if let locationName = docData["locationName"] as? String, let locationIsPublic = docData["locationIsPublic"] as? Bool {
                                if locationIsPublic {
                                    self.locationLabel.text = locationName
                                    self.locationImageView.isHidden = false
                                    self.locationLabel.isHidden = false
                                }
                            }
                        }
                    }
                    
                }
            }
            
            self.updateTopViewUIOfOwnProfile()
            
            self.userOfProfile = currentUser
            
            self.getBadges(user: currentUser)
            
            self.getPosts(getMore: true)
            
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" { // That means its me, Malte
                blogPostButton.isHidden = false
            }
            
            if let displayName = user.displayName {
                nameLabel.text = displayName
                currentUser.displayName = displayName
            }
            if let url = user.photoURL {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                
                currentUser.imageURL = url.absoluteString
                self.imageURL = url.absoluteString
            }
        }
    }
    
    func setUserProfile() {
        
        if let user = userOfProfile {
            self.nameLabel.text = user.displayName
            self.imageURL = user.imageURL
            self.statusLabel.text = user.statusQuote
            
            if let url = URL(string: user.imageURL) {
                self.profilePictureImageView.sd_setImage(with: url, completed: nil)
            } else {
                self.profilePictureImageView.image = UIImage(named: "default-user")
            }
            
            self.getBadges(user: user)
            
            getPosts(getMore: true)
            
            //Social Media Buttons
            var medias = [SocialMediaObject]()
            
            if let instagramLink = user.instagramLink {
                let media = SocialMediaObject(type: .instagram, link: instagramLink, description: user.instagramDescription)
                medias.append(media)
            }
            if let patreonLink = user.patreonLink {
                let media = SocialMediaObject(type: .patreon, link: patreonLink, description: user.patreonDescription)
                medias.append(media)
            }
            if let youTubeLink = user.youTubeLink {
                let media = SocialMediaObject(type: .youTube, link: youTubeLink, description: user.youTubeDescription)
                medias.append(media)
            }
            if let twitterLink = user.twitterLink {
                let media = SocialMediaObject(type: .twitter, link: twitterLink, description: user.twitterDescription)
                medias.append(media)
            }
            if let songwhipLink = user.songwhipLink {
                let media = SocialMediaObject(type: .songwhip, link: songwhipLink, description: user.songwhipDescription)
                medias.append(media)
            }
            
            if medias.count != 0 {
                self.socialMediaObjects = medias
                self.setSocialMediaBar(socialMediaObjects: medias)
            }
            
            if user.locationIsPublic {
                if let location = user.locationName {
                    self.locationLabel.text = location
                    self.locationImageView.isHidden = false
                    self.locationLabel.isHidden = false
                }
            }
        }
    }
    
    func setSocialMediaBar(socialMediaObjects: [SocialMediaObject]) {
        
        for media in socialMediaObjects {
            setUpSocialMediaButton(media: media)
        }
        self.tableView.beginUpdates()
        self.socialMediaInteractionBarHeightConstraint.constant = socialMediaStackViewHeight
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }
        self.tableView.endUpdates()
    }
    
    func setUpSocialMediaButton(media: SocialMediaObject) {
        
        let button = DesignableButton(frame: CGRect(x: 0, y: 0, width: socialMediaStackViewHeight, height: socialMediaStackViewHeight))
        if #available(iOS 13.0, *) {
            button.backgroundColor = .systemBackground
            button.tintColor = .label
        } else {
            button.backgroundColor = .white
            button.tintColor = .black
        }
        button.isOpaque = true
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.cornerRadius = 6
        button.imageView?.contentMode = .scaleAspectFit
        
        switch media.type {
        case .instagram:
            button.addTarget(self, action: #selector(instagramButtonTapped), for: .touchUpInside)
            button.setImage(UIImage(named: "InstagramIcon"), for: .normal)
        case .patreon:
            button.addTarget(self, action: #selector(patreonButtonTapped), for: .touchUpInside)
            button.setImage(UIImage(named: "PatreonIcon"), for: .normal)
        case .youTube:
            button.addTarget(self, action: #selector(youTubeButtonTapped), for: .touchUpInside)
            button.setImage(UIImage(named: "YouTubeButtonIcon"), for: .normal)
        case .twitter:
            button.addTarget(self, action: #selector(twitterButtonTapped), for: .touchUpInside)
            button.setImage(UIImage(named: "TwitterIcon"), for: .normal)
        case .songwhip:
            button.addTarget(self, action: #selector(songwhipButtonTapped), for: .touchUpInside)
            button.setImage(UIImage(named: "MusicIcon"), for: .normal)
        }
        
        socialMediaInteractionStackView.addArrangedSubview(button)
    }
    
    @objc func patreonButtonTapped() {
        if let medias = socialMediaObjects {
            for media in medias {
                if media.type == .patreon {
                    if let _ = media.description {
                        var open = true
                        if self.currentSocialMediaInDescription?.type == .patreon {
                            open = false
                        }
                        self.changeSocialMediaDescriptionViewHeight(open: open, media: media)
                    } else {
                        self.openURL(url: media.link)
                    }
                }
            }
        }
    }
    
    @objc func instagramButtonTapped() {
        if let medias = socialMediaObjects {
            for media in medias {
                if media.type == .instagram {
                    if let _ = media.description {
                        var open = true
                        if self.currentSocialMediaInDescription?.type == .instagram {
                            open = false
                        }
                        self.changeSocialMediaDescriptionViewHeight(open: open, media: media)
                    } else {
                        self.openURL(url: media.link)
                    }
                }
            }
        }
    }
    
    @objc func youTubeButtonTapped() {
        if let medias = socialMediaObjects {
            for media in medias {
                if media.type == .youTube {
                    if let _ = media.description {
                        var open = true
                        if self.currentSocialMediaInDescription?.type == .youTube {
                            open = false
                        }
                        self.changeSocialMediaDescriptionViewHeight(open: open, media: media)
                    } else {
                        self.openURL(url: media.link)
                    }
                }
            }
        }
    }
    
    @objc func twitterButtonTapped() {
        if let medias = socialMediaObjects {
            for media in medias {
                if media.type == .twitter {
                    if let _ = media.description {
                        var open = true
                        if self.currentSocialMediaInDescription?.type == .twitter {
                            open = false
                        }
                        self.changeSocialMediaDescriptionViewHeight(open: open, media: media)
                    } else {
                        self.openURL(url: media.link)
                    }
                }
            }
        }
    }
    
    @objc func songwhipButtonTapped() {
        if let medias = socialMediaObjects {
            for media in medias {
                if media.type == .songwhip {
                    if let _ = media.description {
                        var open = true
                        if self.currentSocialMediaInDescription?.type == .songwhip {
                            open = false
                        }
                        self.changeSocialMediaDescriptionViewHeight(open: open, media: media)
                    } else {
                        if let url = URL(string: media.link) {
                            performSegue(withIdentifier: "showLeanLink", sender: url)
                        } else {
                            self.alert(message: "Kein gültiger Link verfügbar")
                        }
                    }
                }
            }
        }
    }
    
    func openURL(url: String) {
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        } else {
            self.alert(message: "Kein gültiger Link verfügbar")
        }
    }
    
    var currentSocialMediaInDescription: SocialMediaObject?
    
    func changeSocialMediaDescriptionViewHeight(open: Bool, media: SocialMediaObject) {
       
        if self.socialMediaDescriptionViewHeight.constant >= 50 {   //is open
            self.tableView.beginUpdates()
            self.socialMediaDescriptionViewHeight.constant = 0
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.socialMediaDescriptionLabel.alpha = 0
                self.socialMediaDescriptionButton.alpha = 0
                self.socialMediaDescriptionImageView.alpha = 0
            } completion: { (_) in  //now closed
                self.currentSocialMediaInDescription = nil
                self.socialMediaDescriptionLabel.text = nil
                self.socialMediaDescriptionImageView.image = nil
                if open {   //open it again with the intended media
                    self.changeSocialMediaDescriptionViewHeight(open: true, media: media)
                }
            }
            
            self.tableView.endUpdates()
        } else {                                                    //is closed
            self.tableView.beginUpdates()
            self.socialMediaDescriptionViewHeight.constant = 50
            self.setSocialMediaDescriptionImageView(media: media)

            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.socialMediaDescriptionImageView.alpha = 1
                self.socialMediaDescriptionLabel.alpha = 1
                self.socialMediaDescriptionButton.alpha = 1
            } completion: { (_) in  //now Open
                self.currentSocialMediaInDescription = media
                self.socialMediaDescriptionLabel.text = media.description
            }
            
            self.tableView.endUpdates()
        }
    }
    
    func setSocialMediaDescriptionImageView(media: SocialMediaObject) {
        let imageView = socialMediaDescriptionImageView!
        
        switch media.type {
        case .instagram:
            imageView.image = UIImage(named: "InstagramIcon")
        case .patreon:
            imageView.image = UIImage(named: "PatreonIcon")
        case .youTube:
            imageView.image = UIImage(named: "YouTubeButtonIcon")
        case .twitter:
            imageView.image = UIImage(named: "TwitterIcon")
        case .songwhip:
            imageView.image = UIImage(named: "MusicIcon")
        }
    }
    
    
    @IBAction func socialMediaDescriptionButtonTapped(_ sender: Any) {
        if let media = currentSocialMediaInDescription {
            if let url = URL(string: media.link) {
                if media.type == .songwhip {
                    performSegue(withIdentifier: "showLeanLink", sender: url)
                } else {
                    UIApplication.shared.open(url)
                }
            } else {
                self.alert(message: "Kein gültiger Link verfügbar")
            }
        }
    }
    
    func updateTopViewUIOfOwnProfile() {
        self.tableView.beginUpdates()
        interactionBarHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
        self.tableView.endUpdates()
    }
    
    func getBadges(user: User) {
        user.getBadges { (badges) in
            for badge in badges {
                if badge == "first500" {
                    self.firstBadgeImageView.image = UIImage(named: "First500Badge")
                } else if badge == "mod" {
                    self.secondBadgeImageView.image = UIImage(named: "ModBadge")
                }
            }
        }
    }
    
    func checkIfAlreadyFriends() {
        if let user = Auth.auth().currentUser {
            if let currentProfile = userOfProfile {
                if currentProfile.userUID == "" {
                    
                    if user.uid == currentProfile.userUID {    // Your profile but you view it as a stranger, the people want to see a difference, like: "Well this is how other people see my profile..."
                        self.addAsFriendButton.isHidden = true
                        self.chatWithUserButton.isHidden = true
                        
                        self.currentState = .ownProfile
                    } else { // Check if you are already friends or you have requested it
                        let friendsRef = db.collection("Users").document(user.uid).collection("friends").document(currentProfile.userUID)
                        
                        friendsRef.getDocument { (document, err) in
                            if let err = err {
                                print("We have an error getting the friends of our user: \(err.localizedDescription)")
                            } else {
                                if let document = document {
                                    // Got a document with this uid
                                    if let docData = document.data() {
                                        
                                        if let accepted = docData["accepted"] as? Bool {
                                            if accepted {
                                                self.currentState = .friendOfCurrentUser
                                                self.addAsFriendButton.setTitle(NSLocalizedString("remove_as_friend_label", comment: "remove as friend"), for: .normal)
                                            } else {
                                                self.addAsFriendButton.setTitle(NSLocalizedString("friend_request_pending", comment: "is pending"), for: .normal)
                                                self.addAsFriendButton.isEnabled = false
                                            }
                                        }
                                    }
                                    
                                } else {
                                    // not yet befriended
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - SettingsLauncher
    
    lazy var settingsForPicture: SettingsLauncher = {
        let launcher = SettingsLauncher(type: .profilePicture)
        launcher.userFeedVC = self
        return launcher
    }()
    
    lazy var settingForOptions: SettingsLauncher = {
        let launcher = SettingsLauncher(type: .userProfileOptions)
        launcher.userFeedVC = self
        return launcher
    }()
    
    func profilePictureSettingTapped(setting: Setting) {
        switch setting.settingType {
        case .viewPicture:
            if self.imageURL != "" {
                let pinchVC = PinchToZoomViewController()
                pinchVC.imageURL = self.imageURL
                
                self.navigationController?.pushViewController(pinchVC, animated: true)
            }
        case .photoLibrary:
            if let user = userOfProfile {
                performSegue(withIdentifier: "toSettingSegue", sender: user)
            }
        case .blockUser:
            blockUserTapped()
        default:
            print("Das soll nicht passieren")
        }
    }
    
    func blockUserTapped() {
        if let _ = Auth.auth().currentUser {
            if let currentUser = userOfProfile {
                let alert = UIAlertController(title: NSLocalizedString("block_user_alert_title", comment: "block user?"), message: NSLocalizedString("block_user_alert_message", comment: "delete from friends and cant contact you again?"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: "yes"), style: .destructive, handler: { (_) in
                    // block User
                    
                    if let user = Auth.auth().currentUser {
                        let blockRef = self.db.collection("Users").document(user.uid)
                        blockRef.updateData([
                            "blocked": FieldValue.arrayUnion([currentUser.userUID]) // Add the person as blocked
                            ])
                        
                        self.deleteAsFriend()
                    }
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("rather_not", comment: "rather_not"), style: .cancel, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                present(alert, animated: true)
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    //MARK: - TableView
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            print("Nothing will happen")
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            performSegue(withIdentifier: "showPost", sender: post)
        }
    }
    
    
    //MARK: - ImagePickerStuff
    func deletePicture() {  // In Firebase Storage
        if let user = Auth.auth().currentUser {
            let imageName = "\(user.uid).profilePicture"
            let storageRef = Storage.storage().reference().child("profilePictures").child("\(imageName).png")
            
            storageRef.delete { (err) in
                if let err = err {
                    print("We have an error deleting the old profile Picture: \(err.localizedDescription)")
                } else {
                    print("Picture Deleted")
                }
            }
            
        }
    }
    
    
    func savePicture() {
        if let user = Auth.auth().currentUser {
            let imageName = "\(user.uid).profilePicture"
            let storageRef = Storage.storage().reference().child("profilePictures").child("\(imageName).png")
            
            if let uploadData = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.2) {   //Es war das Fragezeichen
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in    //Bild speichern
                    if let error = error {
                        print(error)
                        return
                    } else {
                        print("Picture Saved")
                    }
                    storageRef.downloadURL(completion: { (url, err) in  // Hier wird die URL runtergezogen
                        if let err = err {
                            print(err)
                            return
                        }
                        
                        if let url = url {
                            self.imageURL = url.absoluteString
                        }
                        
                        self.savePictureInUserDatabase()
                        
                        
                    })
                })
            }
            
        }
    }
    
    func savePictureInUserDatabase() {
        let user = Auth.auth().currentUser
        if let user = user {
            let changeRequest = user.createProfileChangeRequest()
            
            if let url = URL(string: imageURL) {
                changeRequest.photoURL = url
            }
            changeRequest.commitChanges { error in
                if error != nil {
                    // An error happened.
                    print("Wir haben einen error beim changeRequest: \(String(describing: error?.localizedDescription))")
                } else {
                    // Profile updated.
                    print("changeRequest hat geklappt")
                }
            }
            let userRef = db.collection("Users").document(user.uid)
            userRef.setData(["profilePictureURL": imageURL], mergeFields:["profilePictureURL"]) // MergeFields, so the other data wont be overridden
        }
        
    }
    
    //Image Picker stuff
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        profilePictureImageView.image = selectedImageFromPicker
        
        if imageURL != "" {
            deletePicture()
            savePicture()
        } else {    // If the user got no profile picture
            savePicture()
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func moreButtonTapped(_ sender: Any) {
        //Show blockOptions settings
        settingForOptions.showSettings(for: nil)
    }
    
    @IBAction func profilePicturePressed(_ sender: Any) {
        guard let state = currentState else { return }
        
        switch state {
        case .ownProfileWithEditing:
            settingsForPicture.showSettings(for: nil)

        default:
            // Just show the Image
            let pinchVC = PinchToZoomViewController()
            
            pinchVC.imageURL = self.imageURL
            self.navigationController?.pushViewController(pinchVC, animated: true)
        }
    }
    
    @objc func logOutTapped() {
        let alert = UIAlertController(title: NSLocalizedString("log_out", comment: "log_out"), message: NSLocalizedString("we_will_meet_again", comment: "we_will_meet_again"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("log_out", comment: "log_out"), style: .destructive , handler: { (_) in
            // abmelden
            do {
                try Auth.auth().signOut()
                print("Log Out successful")
                self.delegate?.deleteListener()
                self.navigationController?.popViewController(animated: true)
            } catch {
                print("Log Out not successfull")
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("rather_not", comment: "rather not"), style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true)
    }
    
    
    @IBAction func blogPostTapped(_ sender: Any) {
        performSegue(withIdentifier: "toBlogPost", sender: nil)
    }
    
    
    @IBAction func toSettingsTapped(_ sender: Any) {
        
        if let user = userOfProfile {
            performSegue(withIdentifier: "toSettingSegue", sender: user)
        }
    }
    
    @IBAction func addAsFriendTapped(_ sender: Any) {
        
        guard let state = currentState else { return }
        
        if let _ = Auth.auth().currentUser {
            switch state {
            case .friendOfCurrentUser:
                // Unfollow this person
                
                let alert = UIAlertController(title: NSLocalizedString("delete_friend_alert_title", comment: "delete friend?"), message: NSLocalizedString("delete_friend_alert_message", comment: "delete as friend?"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { (_) in
                    self.deleteAsFriend()
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: .cancel, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true) {
                }
                
            case .otherUser:
                // Follow/Befriend this person
                self.sendInvitation()
                
            case .blockedToInteract:
                print("not allowed to send invitation because blocked")
            default:
                print("nothing should happen here")
            }
        } else {
            self.notLoggedInAlert()
        }
        
    }
    
    func sendInvitation() {
        self.view.activityStartAnimating()
        if let user = Auth.auth().currentUser {
            if let currentProfile = userOfProfile {
                
                let friendsRef = db.collection("Users").document(currentProfile.userUID).collection("friends").document(user.uid)
                let data: [String:Any] = ["accepted": false, "requestedAt" : Timestamp(date: Date())]
                
                let notificationsRef = db.collection("Users").document(currentProfile.userUID).collection("notifications").document()
                var notificationData : [String: Any] = ["type": "friend", "name": user.displayName, "userID": user.uid]
                
                let language = LanguageSelection().getLanguage()
                if language == .english {
                    notificationData["language"] = "en"
                }
                notificationsRef.setData(notificationData) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        print("Successfully saved the notification")
                    }
                }
                
                friendsRef.setData(data) { (error) in
                    if error != nil {
                        print("We couldnt add as Friend: Error \(error?.localizedDescription ?? "No error")")
                    } else {
                        // Notify User
                        let alert = UIAlertController(title: NSLocalizedString("add_friend_alert_title", comment: "send"), message: NSLocalizedString("add_friend_alert_message", comment: "susccessfully send"), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                            
                        }))
                        self.present(alert, animated: true) {
                            self.view.activityStopAnimating()
                            self.addAsFriendButton.setTitle(NSLocalizedString("friend_request_pending", comment: "pending"), for: .normal)
                        }
                    }
                }
            }
        }
    }
    
    func deleteAsFriend() {
        if let user = Auth.auth().currentUser {
            if let currentProfile = userOfProfile {
                
                let friendsRefOfCurrentProfile = db.collection("Users").document(currentProfile.userUID).collection("friends").document(user.uid)
                friendsRefOfCurrentProfile.delete()
                
                let friendsRefOfLoggedInUser = db.collection("Users").document(user.uid).collection("friends").document(currentProfile.userUID)
                friendsRefOfLoggedInUser.delete()
                
                
                // Notify User
                let alert = UIAlertController(title: NSLocalizedString("done_delete_friend_alert_title", comment: "done"), message: NSLocalizedString("done_delete_friend_alert_message", comment: "successfully deleted"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                self.present(alert, animated: true) {
                    self.addAsFriendButton.setTitle(NSLocalizedString("add_as_friend_label", comment: "add as afriend"), for: .normal)
                    self.currentState = .otherUser
                    self.addAsFriendButton.isEnabled = false
                }
                
            }
        }
    }
    
    @IBAction func chatWithUserTapped(_ sender: Any) {
        
        guard let state = currentState else { return }
        
        if let _ = Auth.auth().currentUser {
            switch state {
            case .blockedToInteract:
                print("Not allowed to send message because blocked")
            default:
                self.checkIfThereIsAlreadyAChat()
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    
    func checkIfThereIsAlreadyAChat() {
        if let profileUser = userOfProfile {
            if let currentUser = Auth.auth().currentUser {
                
                // Check if there is already a chat
                let chatRef = db.collection("Users").document(currentUser.uid).collection("chats").whereField("participant", isEqualTo: profileUser.userUID).limit(to: 1)
                
                chatRef.getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("We have an error downloading the chat: \(error.localizedDescription)")
                    } else {
                        if querySnapshot!.isEmpty { // Create a new chat
                            self.createNewChat()
                        } else {
                            if let document = querySnapshot?.documents.last {
                                self.goToExistingChat(participant: profileUser, document: document)
                            } else {
                                self.createNewChat()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createNewChat() {
        if let profileUser = userOfProfile {
            if let loggedInUser = Auth.auth().currentUser {
                let chat = Chat()
                let newChatRef = self.db.collection("Chats").document()
                let newDocumentID = newChatRef.documentID
                
                chat.participant = profileUser
                chat.documentID = newDocumentID
                
                newChatRef.setData(["participants": [profileUser.userUID, loggedInUser.uid]]) { (err) in
                    if let error = err {
                        print("We have an error: ", error.localizedDescription)
                    }
                }
                
                // Create Chat Reference for the current User
                let dataForCurrentUsersDatabase = ["participant": chat.participant.userUID]
                let currentUsersDatabaseRef = self.db.collection("Users").document(loggedInUser.uid).collection("chats").document(newDocumentID)
                
                currentUsersDatabaseRef.setData(dataForCurrentUsersDatabase) { (err) in
                    if let error = err {
                        print("We have an error when saving chat for current User: \(error.localizedDescription)")
                    }
                }
                
                // Create Chat Reference for the User of the profile
                let dataForProfileUsersDatabase = ["participant": loggedInUser.uid]
                let profileUsersDatabaseRef = self.db.collection("Users").document(profileUser.userUID).collection("chats").document(newDocumentID)
                
                profileUsersDatabaseRef.setData(dataForProfileUsersDatabase) { (err) in
                    if let error = err {
                        print("We have an error when saving chat for profile User: \(error.localizedDescription)")
                    }
                }
                
                self.performSegue(withIdentifier: "toChatSegue", sender: chat)
            }
        }
    }
    
    func goToExistingChat(participant:User, document:DocumentSnapshot) {
        let chat = Chat()
        let documentID = document.documentID
        
        chat.documentID = documentID
        chat.participant = participant
        
        self.performSegue(withIdentifier: "toChatSegue", sender: chat)
    }
    
    //MARK: - PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatSegue" {
            if let chosenChat = sender as? Chat {
                if let chatVC = segue.destination as? ChatViewController {
                    chatVC.chat = chosenChat
                    chatVC.chatSetting = .normal
                }
            }
        }
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "meldenSegue" {
            if let chosenPost = sender as? Post {
                if let reportVC = segue.destination as? ReportViewController {
                    reportVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "toFactSegue" {
            if let fact = sender as? Community {
                if let factVC = segue.destination as? ArgumentPageViewController {
                    factVC.fact = fact
                }
            }
        }
        if segue.identifier == "toSettingSegue" {
            if let user = sender as? User {
                if let vc = segue.destination as? SettingTableViewController {
                    vc.user = user
                    vc.settingFor = .userProfile
                }
            }
        }
        if segue.identifier == "showLeanLink" {
            if let url = sender as? URL {
                if let vc = segue.destination as? LeanWebViewViewController {
                    vc.link = url
                }
            }
        }
    }
}

extension UIImagePickerController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
}



extension UITableView {
    func updateHeaderViewHeight() {
        if let header = self.tableHeaderView {
            let newSize = header.systemLayoutSizeFitting(CGSize(width: self.bounds.width, height: 0))
            header.frame.size.height = newSize.height
        }
    }
}
