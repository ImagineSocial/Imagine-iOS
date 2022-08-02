//
//  UserFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SwiftLinkPreview
import FirebaseAuth
import FirebaseFirestore
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
    
    
    /* You have to set currentState and userOfProfile when you call this VC - Couldnt get the init to work */
    
    var imagePicker = UIImagePickerController()
    var selectedImageFromPicker = UIImage(named: "default-user")
    var user: User?
    
    var currentState: AccessState?
    
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
        layer.borderColor = UIColor.secondarySystemBackground.cgColor
        
        chatWithUserButton.layer.borderColor = UIColor.tertiaryLabel.cgColor
        addAsFriendButton.layer.borderColor = UIColor.tertiaryLabel.cgColor
        chatWithUserButton.layer.borderWidth = 0.75
        addAsFriendButton.layer.borderWidth = 0.75
        
        setPlaceholders()
        setCurrentState()   // check if blocked or own profile
        setBarButtonItem()
        navigationController?.hideHairline()
        
        imagePicker.delegate = self
        
        let profileInfoShown = UserDefaults.standard.bool(forKey: "userFeedInfo")
        if !profileInfoShown {
            showInfoView()
        }
    }
    
    func showInfoView() {
        let height = topbarHeight + 40
        
        let frame = CGRect(x: 20, y: 20, width: self.view.frame.width-40, height: self.view.frame.height-height)
        let popUpView = PopUpInfoView(frame: frame)
        popUpView.alpha = 0
        popUpView.type = .userFeed
        
        
        if let window = UIApplication.keyWindow() {
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
        //Check if allowed to load
        guard let user = AuthenticationManager.shared.user, let profileUser = self.user, let blocked = profileUser.blocked else {
            getUserDetails()
            return
        }
        
        blocked.forEach { id in
            if id == user.uid {
                currentState = .blockedToInteract
                view.activityStopAnimating()

                return
            }
        }
        
        getUserDetails()
    }
    
    func getUserDetails() {
        
        guard let state = currentState else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        switch state {
        case .ownProfile:
            setOwnProfile()
            getPosts()
            noPostsType = .userProfile
        case .ownProfileWithEditing:
            isOwnProfile = true
            settingButton.isHidden = false
            noPostsType = .ownProfile
            setOwnProfile()
            getPosts()
        case .otherUser:
            checkIfAlreadyFriends()
            setUserProfile()
            getPosts()
            noPostsType = .userProfile
        case .friendOfCurrentUser:
            addAsFriendButton.setTitle(NSLocalizedString("remove_as_friend_label", comment: "remove as friend"), for: .normal)
            setUserProfile()
            getPosts()
            noPostsType = .userProfile
        case .blockedToInteract:
            profilePictureImageView.image = UIImage(named: "default-user")
            if let currentUser = user {
                nameLabel.text = currentUser.name  //Blocked means not befriended, so it shows the username
            }
        }
    }
    
    override func getPosts() {
        
        guard let currentState = currentState else { return }
        
        switch currentState {
        case .blockedToInteract:
            self.refreshControl?.endRefreshing()
            return
        default:
            guard isConnected(), let userID = user?.uid else {
                fetchRequested = !isConnected()
                return
            }
            
            view.activityStartAnimating()
            
            firestoreManager.getUserPosts(userID: userID) { posts in
                guard let posts = posts else {
                    print("No Posts")
                    DispatchQueue.main.async {
                        self.view.activityStopAnimating()
                    }
                    return
                }
                
                self.placeholderAreShown ? self.setPosts(posts) : self.appendPosts(posts)
            }
        }
    }
    
    
    // MARK: - SetUI
    
    func setBarButtonItem() {
        
        guard let state = currentState else { return }
        
        switch state {
        case .ownProfileWithEditing:
            
            let LogOutButton = DesignableButton(title: "Log-Out", font: UIFont(name: "IBMPlexSans-Medium", size: 16))
            LogOutButton.setTitleColor(UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0), for: .normal)
            LogOutButton.addTarget(self, action: #selector(self.logOutTapped), for: .touchUpInside)
            LogOutButton.constrain(width: 70, height: 30)
            
            let rightBarButton = UIBarButtonItem(customView: LogOutButton)
            self.navigationItem.rightBarButtonItem = rightBarButton
        case .ownProfile:
            break
        // You can block someone who blocked you for now
        default:
            self.moreButton.isHidden = false
        }
    }
    
    func setOwnProfile() {
        
        chatWithUserButton.isHidden = true // Not possible to message yourself
        addAsFriendButton.isHidden = true
        profilePictureButton.isEnabled = true
        
        guard let userID = AuthenticationManager.shared.userID else {
            return
        }
        
        let ref = db.collection("Users").document(userID)
        
        FirestoreManager.shared.decodeSingle(reference: ref) { (result: Result<User, Error>) in
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                print("We have an error: \(error.localizedDescription)")
            }
        }
        
        setUserProfile()
        
        updateTopViewUIOfOwnProfile()
        
        if userID == "CZOcL3VIwMemWwEfutKXGAfdlLy1" { // That means its me, Malte
            blogPostButton.isHidden = false
        }
    }
    
    func setUserProfile() {
        
        guard let user = user else {
            return
        }
        
        nameLabel.text = user.name
        statusLabel.text = user.statusText
        
        if let urlString = user.imageURL, let url = URL(string: urlString) {
            profilePictureImageView.sd_setImage(with: url, completed: nil)
        } else {
            profilePictureImageView.image = UIImage(named: "default-user")
        }
        
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
        
        totalPostCountLabel.text = String(user.postCount ?? 0)

        if user.locationIsPublic ?? false {
            if let location = user.locationName {
                self.locationLabel.text = location
                self.locationImageView.isHidden = false
                self.locationLabel.isHidden = false
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
        
        let button = DesignableButton(cornerRadius: 6, backgroundColor: .systemBackground)
        button.frame = CGRect(x: 0, y: 0, width: socialMediaStackViewHeight, height: socialMediaStackViewHeight)
        button.isOpaque = true
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
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
            } completion: { (_) in  //now closed
                self.currentSocialMediaInDescription = nil
                self.socialMediaDescriptionLabel.text = nil
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
        let image: UIImage?
        
        switch media.type {
        case .instagram:
            image = UIImage(named: "InstagramIcon")
        case .patreon:
            image = UIImage(named: "PatreonIcon")
        case .youTube:
            image = UIImage(named: "YouTubeButtonIcon")
        case .twitter:
            image = UIImage(named: "TwitterIcon")
        case .songwhip:
            image = UIImage(named: "MusicIcon")
        }
        
        socialMediaDescriptionButton.imageView?.contentMode = .scaleAspectFit
        socialMediaDescriptionButton.setImage(image, for: .normal)
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
    
    func checkIfAlreadyFriends() {
        if let user = Auth.auth().currentUser, let currentProfile = self.user, let userID = currentProfile.uid {
            
            if user.uid == currentProfile.uid {    // Your profile but you view it as a stranger, the people want to see a difference, like: "Well this is how other people see my profile..."
                self.addAsFriendButton.isHidden = true
                self.chatWithUserButton.isHidden = true
                
                self.currentState = .ownProfile
            } else { // Check if you are already friends or you have requested it
                let friendsRef = db.collection("Users").document(user.uid ).collection("friends").document(userID)
                
                friendsRef.getDocument { (document, err) in
                    if let err = err {
                        print("We have an error getting the friends of our user: \(err.localizedDescription)")
                    } else {
                        if let document = document, let docData = document.data(), let accepted = docData["accepted"] as? Bool {
                            if accepted {
                                self.currentState = .friendOfCurrentUser
                                self.addAsFriendButton.setTitle(NSLocalizedString("remove_as_friend_label", comment: "remove as friend"), for: .normal)
                            } else {
                                self.addAsFriendButton.setTitle(NSLocalizedString("friend_request_pending", comment: "is pending"), for: .normal)
                                self.addAsFriendButton.isEnabled = false
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
            if let user = user, let imageURL = user.imageURL {
                let pinchVC = PinchToZoomViewController()
                pinchVC.imageURL = imageURL
                
                self.navigationController?.pushViewController(pinchVC, animated: true)
            }
        case .photoLibrary:
            if let user = user {
                performSegue(withIdentifier: "toSettingSegue", sender: user)
            }
        case .blockUser:
            blockUserTapped()
        default:
            print("Das soll nicht passieren")
        }
    }
    
    func blockUserTapped() {
        if let userID = AuthenticationManager.shared.user?.uid {
            if let userOfProfileID = user {
                let alert = UIAlertController(title: NSLocalizedString("block_user_alert_title", comment: "block user?"), message: NSLocalizedString("block_user_alert_message", comment: "delete from friends and cant contact you again?"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: "yes"), style: .destructive){ _ in
                    // block User
                    let blockRef = self.db.collection("Users").document(userID)
                    blockRef.updateData([
                        "blocked": FieldValue.arrayUnion([userOfProfileID]) // Add the person as blocked
                    ])
                    
                    self.deleteAsFriend()
                })
                alert.addAction(UIAlertAction(title: NSLocalizedString("rather_not", comment: "rather_not"), style: .cancel) { _ in
                    alert.dismiss(animated: true, completion: nil)
                })
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
        if let userID = AuthenticationManager.shared.user?.uid {
            let imageName = "\(userID).profilePicture"
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
        guard let userID = AuthenticationManager.shared.user?.uid else { return }
        
        let imageName = "\(userID).profilePicture"
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
                    
                    if let url = url?.absoluteString {
                        self.user?.imageURL = url
                        self.savePictureInUserDatabase(url: url)
                    }
                })
            })
        }
        
    }
    
    func savePictureInUserDatabase(url: String) {

        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            
            if let url = URL(string: url) {
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
            userRef.setData(["profilePictureURL": url], mergeFields:["profilePictureURL"]) // MergeFields, so the other data wont be overridden
        }
    }
    
    //Image Picker stuff
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        profilePictureImageView.image = selectedImageFromPicker
        
        if user?.imageURL != nil {
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
            guard let imageURL = user?.imageURL else { return }
            // Just show the Image
            let pinchVC = PinchToZoomViewController()
            
            pinchVC.imageURL = imageURL
            self.navigationController?.pushViewController(pinchVC, animated: true)
        }
    }
    
    @objc func logOutTapped() {
        let alert = UIAlertController(title: NSLocalizedString("log_out", comment: "log_out"), message: NSLocalizedString("we_will_meet_again", comment: "we_will_meet_again"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("log_out", comment: "log_out"), style: .destructive) { _ in
            self.dismissViewAndRemoveUser()
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("rather_not", comment: "rather not"), style: .cancel) { _ in
            alert.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true)
    }
    
    private func dismissViewAndRemoveUser() {
        AuthenticationManager.shared.logOut { success in
            self.delegate?.deleteListener()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    @IBAction func blogPostTapped(_ sender: Any) {
        performSegue(withIdentifier: "toBlogPost", sender: nil)
    }
    
    
    @IBAction func toSettingsTapped(_ sender: Any) {
        
        if let user = user {
            performSegue(withIdentifier: "toSettingSegue", sender: user)
        }
    }
    
    @IBAction func addAsFriendTapped(_ sender: Any) {
        
        guard let state = currentState else { return }
        
        if AuthenticationManager.shared.isLoggedIn {
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
        if let user = Auth.auth().currentUser, let currentProfileID = self.user?.uid,  let name = user.displayName {
                
                let friendsRef = db.collection("Users").document(currentProfileID).collection("friends").document(user.uid)
                let data: [String:Any] = ["accepted": false, "requestedAt" : Timestamp(date: Date())]
                
                let notificationsRef = db.collection("Users").document(currentProfileID).collection("notifications").document()
                var notificationData : [String: Any] = ["type": "friend", "name": name, "userID": user.uid]
                
                let language = LanguageSelection.language
                if language == .en {
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
    
    func deleteAsFriend() {
        if let userID = AuthenticationManager.shared.user?.uid, let currentProfileID = user?.uid {
            
            let friendsRefOfCurrentProfile = db.collection("Users").document(currentProfileID).collection("friends").document(userID)
            friendsRefOfCurrentProfile.delete()
            
            let friendsRefOfLoggedInUser = db.collection("Users").document(userID).collection("friends").document(currentProfileID)
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
        if let profileUser = user, let userID = profileUser.uid, let currentUser = Auth.auth().currentUser {
            
            // Check if there is already a chat
            let chatRef = db.collection("Users").document(currentUser.uid).collection("chats").whereField("participant", isEqualTo: userID).limit(to: 1)
            
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
    
    func createNewChat() {
        if let profileUser = user, let userID = profileUser.uid, let loggedInUser = Auth.auth().currentUser {
                let chat = Chat()
                let newChatRef = self.db.collection("Chats").document()
                let newDocumentID = newChatRef.documentID
                
                chat.participant = profileUser
                chat.documentID = newDocumentID
                
                newChatRef.setData(["participants": [userID, loggedInUser.uid]]) { (err) in
                    if let error = err {
                        print("We have an error: ", error.localizedDescription)
                    }
                }
                
                // Create Chat Reference for the current User
                let dataForCurrentUsersDatabase = ["participant": userID]
                let currentUsersDatabaseRef = self.db.collection("Users").document(loggedInUser.uid).collection("chats").document(newDocumentID)
                
                currentUsersDatabaseRef.setData(dataForCurrentUsersDatabase) { (err) in
                    if let error = err {
                        print("We have an error when saving chat for current User: \(error.localizedDescription)")
                    }
                }
                
                // Create Chat Reference for the User of the profile
                let dataForProfileUsersDatabase = ["participant": loggedInUser.uid]
                let profileUsersDatabaseRef = self.db.collection("Users").document(userID).collection("chats").document(newDocumentID)
                
                profileUsersDatabaseRef.setData(dataForProfileUsersDatabase) { (err) in
                    if let error = err {
                        print("We have an error when saving chat for profile User: \(error.localizedDescription)")
                    }
                }
                
                self.performSegue(withIdentifier: "toChatSegue", sender: chat)
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
            if let community = sender as? Community {
                if let factVC = segue.destination as? CommunityPageVC {
                    factVC.community = community
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
