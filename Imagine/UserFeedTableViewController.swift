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

// LogOutButton
// UserUID abscihern
// Set getMore in UserPostHelper!
class UserFeedTableViewController: BaseFeedTableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var addAsFriendButton: DesignableButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    @IBOutlet weak var profilePictureButton: DesignableButton!
    @IBOutlet weak var blogPostButton: DesignableButton!
    @IBOutlet weak var chatWithUserButton: DesignableButton!
    
    
    var userUID = ""    // Noch absichern
    lazy var postHelper = UserPostHelper()
    
    var imagePicker = UIImagePickerController()
    var imageURL = ""
    var selectedImageFromPicker = UIImage(named: "default-user")
    var userOfProfile:User?
    var yourOwnProfile = false
    var alreadyFriends = false
    
    let db = Firestore.firestore()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blogPostButton.isHidden = true
        
        if userUID == "" { // If you come from the side Menu Profile Button
            yourOwnProfile = true
            
            self.chatWithUserButton.isHidden = true // Not possible to message yourself
            self.addAsFriendButton.isHidden = true
            
            profilePictureButton.isEnabled = true
            if let user = Auth.auth().currentUser {
                
                self.userUID = user.uid
                getPosts(getMore: false)
                
                if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" { // That means its me, Malte
                    blogPostButton.isHidden = false
                }
            }
        } else {
            self.navigationItem.rightBarButtonItem = nil
            
            if let user = Auth.auth().currentUser {
                if user.uid == userUID {    // Your profile but you view it as a stranger, the people want to see a difference, like: "Well this is how other people see my profile..."
                    self.addAsFriendButton.isHidden = true
                    self.chatWithUserButton.isHidden = true
                }
            }
            
            getPosts(getMore: true)
            // Kein Add as Friend Button Kein Chat oder Danke Button
            
        }
        getUserDetails()
        
        
        imagePicker.delegate = self
    }
    
    
    func getUserDetails() {
        
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = profilePictureImageView.frame.width/2
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        
        if yourOwnProfile { // If it is your profile
            if let user = Auth.auth().currentUser {
                if let displayName = user.displayName {
                    nameLabel.text = displayName
                }
                if let url = user.photoURL {
                    profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                    
                    self.imageURL = url.absoluteString
                }
            }
        } else {    // If you are looking at another user
            let userRef = db.collection("Users").document(userUID)
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        let name = docData["name"] as? String ?? ""
                        let surname = docData["surname"] as? String ?? ""
                        let profilePictureURL = docData["profilePictureURL"] as? String ?? ""
                        
                        self.nameLabel.text = "\(name) \(surname)"
                        let user = User()
                        user.name = name
                        user.surname = surname
                        user.imageURL = profilePictureURL
                        self.imageURL = profilePictureURL
                        user.userUID = self.userUID
                        
                        self.userOfProfile = user
                        
                        if profilePictureURL != "" {
                            if let url = URL(string: profilePictureURL) {
                                self.profilePictureImageView.sd_setImage(with: url, completed: nil)
                            }
                        }
                    }
                }
                
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "No error")")
                }
            })
            
            // Check if you are already friends or you have requested it
            if let user = Auth.auth().currentUser {
                let friendsRef = db.collection("Users").document(user.uid).collection("friends").whereField("userUID", isEqualTo: userUID).limit(to: 1)
                
                friendsRef.getDocuments { (querySnap, err) in
                    if let err = err {
                        print("We have an error getting the friends of our user: \(err.localizedDescription)")
                    } else {
                        for document in querySnap!.documents {
                            let docData = document.data()
                            
                            if let accepted = docData["accepted"] as? Bool {
                                if accepted {
                                    self.alreadyFriends = true
                                    self.addAsFriendButton.setTitle("Unfollow", for: .normal)
                                } else {
                                    self.addAsFriendButton.setTitle("Angefragt", for: .normal)
                                    self.addAsFriendButton.isEnabled = false
                                }
                            }
                        }
                    }
                }
                
                
            }
        }
    }
    
    //MARK: - SettingsLauncher
    
    lazy var settingsLauncher: SettingsLauncher = {
        let launcher = SettingsLauncher(type: .profilePicture)
        launcher.userFeedVC = self
        return launcher
    }()
    
    func profilePictureSettingTapped(setting: Setting) {
        switch setting.settingType {
        case .viewPicture:
            let pinchVC = PinchToZoomViewController()
            
            pinchVC.imageURL = self.imageURL
            self.navigationController?.pushViewController(pinchVC, animated: true)
        case .camera:
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.cameraDevice = .rear
            
            present(imagePicker, animated: true, completion: nil)
        case .photoLibrary:
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        default:
            print("Das soll nicht passieren")
        }
    }
    
    //MARK: - TableView
    
    
    override func getPosts(getMore: Bool) {
        postHelper.getPosts(whichPostList: .postsFromUser, userUID: userUID) { (posts) in
            
            self.posts = posts
            self.posts.sort(by: { $0.createTime.compare($1.createTime) == .orderedAscending })
            self.tableView.reloadData()
            
            PostHelper().getEvent(completion: { (event) in
                // Lade das eigentlich nur, damit der die Profilbilder und so richtig lädt
                self.tableView.reloadData()
            })
            
            // remove ActivityIndicator incl. backgroundView
            self.actInd.stopAnimating()
            self.container.isHidden = true
            
            self.refreshControl?.endRefreshing()
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        performSegue(withIdentifier: "showPost", sender: post)
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
            //userRef.setData(["profilePictureURL": imageURL], merge: true)
            userRef.setData(["profilePictureURL": imageURL], mergeFields:["profilePictureURL"]) // MergeFields damit die anderen nicht überschrieben werden
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
        // and delete old picture!!!
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Buttons
    
    @IBAction func profilePicturePressed(_ sender: Any) {
        
        if yourOwnProfile {
            settingsLauncher.showSettings(for: nil)
        } else {
            // Just show the Image
            let pinchVC = PinchToZoomViewController()
            
            pinchVC.imageURL = self.imageURL
            self.navigationController?.pushViewController(pinchVC, animated: true)
        }
        
        
    }
    
    
    @IBAction func logOutPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Ausloggen", message: "Wir sehen uns bald wieder!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Abmelden", style: .default, handler: { (_) in
            // abmelden
            do {
                try Auth.auth().signOut()
                self.dismiss(animated: true, completion: nil)
            } catch {
                print("Ausloggen hat nicht funktioniert")
            }
        }))
        alert.addAction(UIAlertAction(title: "Doch nicht!", style: .destructive, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true)
    }
    
    @IBAction func blogPostTapped(_ sender: Any) {
        performSegue(withIdentifier: "toBlogPost", sender: nil)
    }
    
    @IBAction func addAsFriendTapped(_ sender: Any) {
        
        if alreadyFriends {
            // Unfollow this person
        } else {
            if let user = Auth.auth().currentUser {
                
                let data: [String:Any] = ["accepted": false, "requestedAt" : Timestamp(date: Date()), "userUID": user.uid]
                
                let friendsRef = db.collection("Users").document(userUID).collection("friends").document()
                
                friendsRef.setData(data) { (error) in
                    if error != nil {
                        print("We couldnt add as Friend: Error \(error?.localizedDescription ?? "No error")")
                    } else {
                        print("Added as Friend")
                        self.addAsFriendButton.setTitle("Angefragt", for: .normal)
                        // Notify User
                    }
                }
            }
        }
    }
    
    @IBAction func chatWithUserTapped(_ sender: Any) {
        if let profileUser = userOfProfile {
            if let currentUser = Auth.auth().currentUser {
                
                // Check if there is already a chat
                let chatRef = db.collection("Users").document(currentUser.uid).collection("chats").whereField("participant", isEqualTo: profileUser.userUID).limit(to: 1)
                
                chatRef.getDocuments { (querySnapshot, error) in
                    if error != nil {
                        print("We have an error downloading the chat: \(error?.localizedDescription ?? "no error")")
                    } else {
                        if querySnapshot!.isEmpty { // Create a new chat
                            
                            let chat = Chat()
                            chat.participant = profileUser
                            
                            let newChatRef = self.db.collection("Chats").document()
                            chat.documentID = newChatRef.documentID
                            
                            // Create Chat Reference for the current User
                            let dataForCurrentUsersDatabase = ["participant": chat.participant.userUID, "documentID": chat.documentID]
                            let currentUsersDatabaseRef = self.db.collection("Users").document(currentUser.uid).collection("chats").document()
                            
                            currentUsersDatabaseRef.setData(dataForCurrentUsersDatabase) { (error) in
                                if error != nil {
                                    print("We have an error when saving chat for current User: \(error?.localizedDescription ?? "No error")")
                                }
                            }
                            
                            // Create Chat Reference for the User of the profile
                            let dataForProfileUsersDatabase = ["participant": currentUser.uid, "documentID": chat.documentID]
                            let profileUsersDatabaseRef = self.db.collection("Users").document(profileUser.userUID).collection("chats").document()
                            
                            profileUsersDatabaseRef.setData(dataForProfileUsersDatabase) { (error) in
                                if error != nil {
                                    print("We have an error when saving chat for profile User: \(error?.localizedDescription ?? "No error")")
                                }
                            }
                            
                            self.performSegue(withIdentifier: "toChatSegue", sender: chat)
                            
                        } else {    // Go to the existing chat
                            if let document = querySnapshot?.documents.last {
                                let chat = Chat()
                                
                                let documentData = document.data()
                                
                                if let documentID = documentData["documentID"] as? String {
                                    
                                    chat.documentID = documentID
                                    chat.participant = profileUser
                                    
                                    self.performSegue(withIdentifier: "toChatSegue", sender: chat)
                                }
                            }
                        }
                    }
                }
                
                
            }
        }
    }
    
    
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
    }
}
