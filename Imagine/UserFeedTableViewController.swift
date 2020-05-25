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

// This enum represents the different states, when accessing the UserFeedTableVC
enum AccessState{
    case ownProfileWithEditing
    case ownProfile
    case otherUser
    case friendOfCurrentUser
    case blockedToInteract
}

protocol LogOutDelegate {
    func deleteListener()
}

class UserFeedTableViewController: BaseFeedTableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var addAsFriendButton: DesignableButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var profilePictureButton: DesignableButton!
    @IBOutlet weak var blogPostButton: DesignableButton!
    @IBOutlet weak var chatWithUserButton: DesignableButton!
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var moreButton: DesignableButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var messageBubbleImageView: UIImageView!
    @IBOutlet weak var totalPostCountLabel: UILabel!
    
    
    /* You have to set currentState and userOfProfile when you call this VC - Couldnt get the init to work */
    
    var imagePicker = UIImagePickerController()
    var imageURL = ""
    var selectedImageFromPicker = UIImage(named: "default-user")
    var userOfProfile:User?
    var totalCountOfPosts = 0
    
    var currentState:AccessState?
    
    var delegate: LogOutDelegate?
    
    let defaultStatusText = "Hier steht dein Status"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.navigationController?.navigationBar.isTranslucent = false
        
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = .secondarySystemBackground
            self.navigationController?.view.backgroundColor = .secondarySystemBackground
        } else {
            self.view.backgroundColor = .ios12secondarySystemBackground
            self.navigationController?.view.backgroundColor = .ios12secondarySystemBackground
        }
        
        
        self.moreButton.isHidden = true
        cameraView.isHidden = true
        blogPostButton.isHidden = true
        statusTextView.isEditable = false
        statusTextView.delegate = self
        
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = 8
        layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.secondarySystemBackground.cgColor
        } else {
            layer.borderColor = UIColor.lightGray.cgColor
        }
        
        checkIfBlocked()
        setBarButtonItem()
        
        imagePicker.delegate = self
    }
    
    func checkIfBlocked() {
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
                    
                    postHelper.getPostList(getMore: getMore, whichPostList: .postsFromUser, userUID: user.userUID) { (posts, initialFetch)  in
                        
                        guard let posts = posts else {
                            print("No more Posts")
                            self.view.activityStopAnimating()
                            
                            return
                        }
                        
                        if initialFetch {   // Get the first batch of posts
                            self.posts = posts
                            self.tableView.reloadData()
                            self.fetchesPosts = false
                            
                            self.totalCountOfPosts = self.postHelper.getTotalCount()
                            self.totalPostCountLabel.text = String("\(self.totalCountOfPosts) Beiträge")
                            
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
                        print("Jetzt haben wir \(self.posts.count)")
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
            
            cameraView.clipsToBounds = true
            cameraView.layer.cornerRadius = cameraView.frame.width/2
            
            self.cameraView.isHidden = false
        case .ownProfile:
            print("Here will nothing happen")
            
        // You can block someone who blocked you for now
        default:
            self.moreButton.isHidden = false
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
            self.statusTextView.isEditable = true
            self.noPostsType = .ownProfile
            self.setOwnProfile()
        case .otherUser:
            self.checkIfAlreadyFriends()
            self.setCurrentProfile()
            self.noPostsType = .userProfile
        case .friendOfCurrentUser:
            self.addAsFriendButton.setTitle("Freund entfernen", for: .normal)
            self.setCurrentProfile()
            self.noPostsType = .userProfile
        case .blockedToInteract:
            self.profilePictureImageView.image = UIImage(named: "default-user")
            if let currentUser = userOfProfile {
                self.nameLabel.text = currentUser.displayName  //Blocked means not befriended, so it shows the username
            }
        }
    }
    
    func setOwnProfile() {
        
        chatWithUserButton.isHidden = true // Not possible to message yourself
        messageBubbleImageView.isHidden = true
        addAsFriendButton.isHidden = true
        profilePictureButton.isEnabled = true
        
        if let user = Auth.auth().currentUser {
            
            let ref = db.collection("Users").document(user.uid)
            ref.getDocument { (doc, err) in
                if let err = err {
                    print("We have an error: \(err.localizedDescription)")
                } else {
                    if let doc = doc {
                        if let docData = doc.data() {
                            if let statusQuote = docData["statusText"] as? String {
                                if statusQuote != "" {
                                    self.statusTextView.text = statusQuote
                                } else {
                                    self.statusTextView.text = self.defaultStatusText
                                }
                            } else {
                                self.statusTextView.text = self.defaultStatusText
                            }
                        }
                    }
                    
                }
            }
            
            let currentUser = User()
            currentUser.userUID = user.uid
            
            self.userOfProfile = currentUser
            
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
    
    
    func setCurrentProfile() {
        
        //        self.userOfProfile = user
        if let userOfProfile = userOfProfile {
            self.nameLabel.text = userOfProfile.displayName
            self.imageURL = userOfProfile.imageURL
            self.statusTextView.text = userOfProfile.statusQuote
            
            if let url = URL(string: userOfProfile.imageURL) {
                self.profilePictureImageView.sd_setImage(with: url, completed: nil)
            } else {
                self.profilePictureImageView.image = UIImage(named: "default-user")
            }
            
            getPosts(getMore: true)
        }
    }
    
    func checkIfAlreadyFriends() {
        if let user = Auth.auth().currentUser {
            if let currentProfile = userOfProfile {
                
                if user.uid == currentProfile.userUID {    // Your profile but you view it as a stranger, the people want to see a difference, like: "Well this is how other people see my profile..."
                    self.addAsFriendButton.isHidden = true
                    self.chatWithUserButton.isHidden = true
                    self.messageBubbleImageView.isHidden = true
                    
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
                                            self.addAsFriendButton.setTitle("Freund entfernen", for: .normal)
                                        } else {
                                            self.addAsFriendButton.setTitle("Angefragt", for: .normal)
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
        case .camera:
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.cameraDevice = .rear
            
            present(imagePicker, animated: true, completion: nil)
        case .photoLibrary:
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        case .blockUser:
            blockUserTapped()
        default:
            print("Das soll nicht passieren")
        }
    }
    
    func blockUserTapped() {
        if let _ = Auth.auth().currentUser {
            if let currentUser = userOfProfile {
                let alert = UIAlertController(title: "Blocken", message: "Der User wird aus deiner Freundesliste gelöscht und darf dich nicht mehr kontaktieren. Fortfahren? ", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
                    // block User
                    
                    if let user = Auth.auth().currentUser {
                        let blockRef = self.db.collection("Users").document(user.uid)
                        blockRef.updateData([
                            "blocked": FieldValue.arrayUnion([currentUser.userUID]) // Add the person as blocked
                            ])
                        
                        self.deleteAsFriend()
                    }
                }))
                alert.addAction(UIAlertAction(title: "Doch nicht!", style: .cancel, handler: { (_) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                present(alert, animated: true)
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    //MARK: - TableView
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var ownProfile = false
        
        
        switch currentState! {
        case .ownProfileWithEditing:
            ownProfile = true
            
        default:
            ownProfile = false
        }
        
        let post = posts[indexPath.row]
        
        switch post.type {
        case .multiPicture:
            let identifier = "MultiPictureCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MultiPictureCell {
                
                cell.ownProfile = ownProfile
                cell.post = post
                
                return cell
            }
        case .topTopicCell:
            tableView.deselectRow(at: indexPath, animated: false)
        case .repost:
            let identifier = "NibRepostCell"
            
            if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell {
                
                repostCell.ownProfile = ownProfile
                
                repostCell.delegate = self
                repostCell.post = post
                
                return repostCell
            }
            
        case .GIF:
            let identifier = "GIFCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? GifCell {
                
                cell.ownProfile = ownProfile
                cell.post = post
                cell.delegate = self
                
                if let url = URL(string: post.linkURL) {
                    cell.videoPlayerItem = AVPlayerItem.init(url: url)
                    cell.startPlayback()
                }
                
                return cell
            }
            
        case .picture:
            let identifier = "NibPostCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell {
                
                cell.ownProfile = ownProfile
                
                cell.delegate = self
                cell.post = post

                
                return cell
            }
        case .thought:
            let identifier = "NibThoughtCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                
                cell.ownProfile = ownProfile
                
                cell.delegate = self
                cell.post = post

                
                return cell
            }
        case .link:
            let identifier = "NibLinkCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LinkCell {
                
                cell.ownProfile = ownProfile
                
                cell.delegate = self
                cell.post = post

                
                return cell
            }
        case .event:
            let identifier = "NibEventCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? EventCell {
                
                cell.post = post
                
                return cell
            }
        case .youTubeVideo:
            let identifier = "NibYouTubeCell"
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? YouTubeCell {
                
                cell.ownProfile = ownProfile
                
                cell.delegate = self
                cell.post = post

                
                return cell
            }
        case .nothingPostedYet:
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NibBlankCell", for: indexPath) as? BlankContentCell {
                
                cell.type = noPostsType
                cell.contentView.backgroundColor = self.tableView.backgroundColor
                
                return cell
            }
        }
        
        
        return UITableViewCell()    
        
    }
    
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
            let userRef = Firestore.firestore().collection("Users").document(user.uid)
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
    
    //MARK: - Buttons
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let text = textView.text {
            if text == defaultStatusText {
                textView.text = ""
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if let text = textView.text {
            if text != defaultStatusText && text != "" {
                if let user = Auth.auth().currentUser {
                    let ref = db.collection("Users").document(user.uid)
                    
                    let data = ["statusText": text]
                    ref.setData(data, mergeFields: ["statusText"])
                }
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {       // If you hit return
            textView.resignFirstResponder()
            return false
        }
        return textView.text.count + (text.count - range.length) <= 45  // Text no longer than 45 characters
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
//            if let user = userOfProfile {
//                performSegue(withIdentifier: "ChangeTheProfileSegue", sender: user)
//            }
        default:
            // Just show the Image
            let pinchVC = PinchToZoomViewController()
            
            pinchVC.imageURL = self.imageURL
            self.navigationController?.pushViewController(pinchVC, animated: true)
        }
    }
    
    @objc func logOutTapped() {
        let alert = UIAlertController(title: "Ausloggen", message: "Wir sehen uns bald wieder!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Abmelden", style: .destructive , handler: { (_) in
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
        alert.addAction(UIAlertAction(title: "Doch nicht!", style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true)
    }
    
    
    @IBAction func blogPostTapped(_ sender: Any) {
        performSegue(withIdentifier: "toBlogPost", sender: nil)
    }
    
    @IBAction func addAsFriendTapped(_ sender: Any) {
        
        guard let state = currentState else { return }
        
        if let _ = Auth.auth().currentUser {
            switch state {
            case .friendOfCurrentUser:
                // Unfollow this person
                
                let alert = UIAlertController(title: "Möchtest du diese Person als Freund löschen?", message: "Wenn du dir sicher bist, klicke auf OK!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { (_) in
                    self.deleteAsFriend()
                }))
                alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: { (_) in
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
                let notificationData : [String: Any] = ["type": "friend", "name": user.displayName, "userID": user.uid]
                
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
                        let alert = UIAlertController(title: "Freundschaft angefragt", message: "Die Freundschaftsanfrage wurde erfolgreich verschickt", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                            
                        }))
                        self.present(alert, animated: true) {
                            self.view.activityStopAnimating()
                            self.addAsFriendButton.setTitle("Angefragt", for: .normal)
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
                let alert = UIAlertController(title: "Freundschaft gelöscht", message: "Die Freundschaft wurde erfolgreich gelöscht", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                self.present(alert, animated: true) {
                    self.addAsFriendButton.setTitle("Gelöscht", for: .normal)
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
                if let reportVC = segue.destination as? MeldenViewController {
                    reportVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "toFactSegue" {
            if let fact = sender as? Fact {
                if let factVC = segue.destination as? ArgumentPageViewController {
                    factVC.fact = fact
                }
            }
        }
        if segue.identifier == "ChangeTheProfileSegue" {
            if let user = sender as? User {
                if let vc = segue.destination as? EditProfileViewController {
                    vc.user = user
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


