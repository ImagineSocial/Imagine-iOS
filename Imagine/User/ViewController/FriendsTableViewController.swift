//
//  FriendsTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 02.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

struct Category {
    let name: String
    var friends: [Friend]
}

class FriendsTableViewController: UITableViewController, RequestDelegate {
    
    var sections = [Category]()
    var alreadyFriends = [Friend]()
    var requestedFriends = [Friend]()
    
    let db = FirestoreRequest.shared.db
    var isNewMessage = false
    
    let handyHelper = HandyHelper.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: "NibBlankCell")
        
        getFriends()
        self.view.activityStartAnimating()
    }
    
    func getFriends() {
        alreadyFriends.removeAll()
        requestedFriends.removeAll()
        sections.removeAll()
        
        if let user = AuthenticationManager.shared.user {
            let friendsRef = db.collection("Users").document(user.uid).collection("friends")
            
            friendsRef.order(by: "accepted", descending: false) // Requests on top
            
            friendsRef.getDocuments { (snapshot, error) in
                
                if error != nil {
                    print("We have an error when we fetch the friends: ", error?.localizedDescription ?? "No error")
                } else {
                    
                    for document in snapshot!.documents {
                        
                        let documentID = document.documentID
                        let documentData = document.data()
                        
                        guard let requestedAt = documentData["requestedAt"] as? Timestamp,
                            let accepted = documentData["accepted"] as? Bool
                            else {
                                return
                        }
                        let friend = Friend()
                        
                        friend.user = User(userID: documentID)
                        friend.accepted = accepted
                        friend.requestedAt = HandyHelper.shared.getStringDate(timestamp: requestedAt)
                        
                        if accepted {
                            self.alreadyFriends.append(friend)
                        } else {
                            // not accepted
                            self.requestedFriends.append(friend)
                        }
                    }
                    
                    
                    self.sections = [Category(name: NSLocalizedString("friendship_requests_label", comment: "friendship_requests_label"), friends: self.requestedFriends),
                                     Category(name: NSLocalizedString("friends_label", comment: "friends_label"), friends: self.alreadyFriends)]
                    self.loadUsers()
                }
            }
        } else {
            self.view.activityStopAnimating()
        }
    }
    
    
    func loadUsers() {
        
        for section in sections {
            for friend in section.friends {
                if let user = friend.user {
                    user.getUser(isAFriend: true) { user in
                        if let user = user {
                            friend.user = user
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
        self.tableView.reloadData()
        self.view.activityStopAnimating()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            if self.tableView(tableView, numberOfRowsInSection: section) > 0 {
                return sections[0].name
            }
        case 1:
            return sections[1].name
        default:
            return nil // when return nil no header will be shown
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 1 && sections[1].friends.count == 0 { // No friends yet
            return 1
        } else {
            let friends = sections[section].friends
            
            return friends.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 && sections[1].friends.count == 0 {   // No friends yet
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NibBlankCell", for: indexPath) as? BlankContentCell {
                
                cell.type = BlankCellType.friends
                
                return cell
            }
        } else {
            let friends = sections[indexPath.section].friends
            let friend = friends[indexPath.row]
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "FriendRequestCell", for: indexPath) as? FriendRequestCell {
                
                cell.delegate = self
                cell.setFriend(friend: friend)
                
                cell.acceptLabel.isHidden = true
                
                
                cell.profilePictureImageView.layer.cornerRadius = 2
                
                if let user = friend.user {
                    cell.nameLabel.text = user.displayName
                    
                    if let urlString = user.imageURL, let url = URL(string: urlString) {
                        cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                    }
                }
                
                if friend.accepted {
                    cell.editButton.isHidden = false
                    cell.stackView.isHidden = true
                } else {    // not accepted Invitation
                    cell.editButton.isHidden = true
                    cell.stackView.isHidden = false
                }
                
                if isNewMessage {
                    cell.editButton.isHidden = true
                    cell.stackView.isHidden = true
                }
                return cell
            }
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sections[0].friends.count == 0 && sections[1].friends.count == 0 {
            return self.view.frame.height-100
        } else {
            return 88
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[0].friends.count == 0 && sections[1].friends.count == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            let friends = sections[indexPath.section].friends
            let friend = friends[indexPath.row]
            
            if isNewMessage {
                goToChatTapped(friend: friend)
            } else {
                performSegue(withIdentifier: "toUserSegue", sender: friend.user)
            }
        }
    }
    
    
    func acceptInvitation(user: User) {
        if let currentUser = AuthenticationManager.shared.user {
            let requestRef = db.collection("Users").document(currentUser.uid).collection("friends").document(user.uid)
            
            requestRef.updateData(["accepted": true])   // Accept and change the database of the current User
            
            let data: [String:Any] = ["accepted": true, "requestedAt" : Timestamp(date: Date())]
            
            let friendRef = db.collection("Users").document(user.uid).collection("friends").document(currentUser.uid)
            
            friendRef.setData(data) { (err) in    // Change Database of the inviter
                if let error = err {
                    print("We have an errror while trying to add a friend: \(error.localizedDescription)")
                } else {
                    self.handyHelper.deleteNotifications(type: .friend, id: user.uid)
                }
            }
            
        }
    }
    
    func declineInvitation(user: User) {
        if let currentUser = AuthenticationManager.shared.user {
            let requestRef = db.collection("Users").document(currentUser.uid).collection("friends").document(user.uid)
            requestRef.delete()
            handyHelper.deleteNotifications(type: .friend, id: user.uid)
        }
    }
    
    lazy var settingsLauncher: SettingsLauncher = {
        let launcher = SettingsLauncher(type: .friendsTableView)
        launcher.FriendsTableVC = self
        return launcher
    }()
    
    func showControllerForSetting(setting: Setting, friend: Friend) {
        
        guard let user = friend.user else { return }
        
        switch setting.settingType {
        case .chatWithUser:
            goToChatTapped(friend: friend)
        case .blockUser:
            let alert = UIAlertController(title: NSLocalizedString("block_user_alert_title", comment: "block user?"), message: NSLocalizedString("block_user_alert_message", comment: "block cant contact u and stuff"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
                // block User
                
                if let currentUser = AuthenticationManager.shared.user, let user = friend.user {
                    let blockRef = self.db.collection("Users").document(currentUser.uid)
                    blockRef.updateData([
                        "blocked": FieldValue.arrayUnion([user.uid]) // Add the person as blocked
                        ])
                    
                    self.deleteFriend(user: user)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("rather_not", comment: "rather_not"), style: .cancel, handler: { (_) in
                alert.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true)
        case .deleteFriend:
            self.deleteFriend(user: user)
        default:
            print("Nichts")
            //            
        }
        
    }
    
    func deleteFriend(user: User) {
        // Unfollow this person
        if let currentUser = AuthenticationManager.shared.user {
            let friendsUID = user.uid
            
            let friendsRefOfCurrentProfile = db.collection("Users").document(friendsUID).collection("friends").document(currentUser.uid)
            friendsRefOfCurrentProfile.delete()
            
            let friendsRefOfLoggedInUser = db.collection("Users").document(currentUser.uid).collection("friends").document(friendsUID)
            friendsRefOfLoggedInUser.delete()
            
            
            // Notify User
            let alert = UIAlertController(title: NSLocalizedString("done_delete_friend_alert_title", comment: "done deleting"), message: NSLocalizedString("done_delete_friend_alert_message", comment: "out of friends list"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
            }))
            self.present(alert, animated: true) {
                self.getFriends()
            }
            
        }
    }
    
    func editButtonTapped(friend: Friend) {
        settingsLauncher.showSettings(for: friend)
    }
    
    
    
    func goToChatTapped(friend: Friend) {
        
        if let currentUser = AuthenticationManager.shared.user, let user = friend.user {
            // Check if there is already a chat
            let chatRef = db.collection("Users").document(currentUser.uid).collection("chats").whereField("participant", isEqualTo: user.uid).limit(to: 1)
            
            chatRef.getDocuments { (querySnapshot, error) in
                if error != nil {
                    print("We have an error downloading the chat: \(error?.localizedDescription ?? "no error")")
                } else {
                    if querySnapshot!.isEmpty { // Create a new chat
                        let newChatRef = self.db.collection("Chats").document()
                        let newDocumentID = newChatRef.documentID
                        
                        let chat = Chat()
                        chat.participant = user
                        chat.documentID = newDocumentID
                        
                        newChatRef.setData(["participants": [user.uid, currentUser.uid]]) { (err) in
                            if let error = err {
                                print("We have an error: \(error.localizedDescription)")
                            }
                        }
                        
                        // Create Chat Reference for the current User
                        let dataForCurrentUsersDatabase = ["participant": user.uid]
                        let currentUsersDatabaseRef = self.db.collection("Users").document(currentUser.uid).collection("chats").document(newDocumentID)
                        
                        currentUsersDatabaseRef.setData(dataForCurrentUsersDatabase) { (error) in
                            if error != nil {
                                print("We have an error when saving chat for current User: \(error?.localizedDescription ?? "No error")")
                            }
                        }
                        
                        // Create Chat Reference for the User of the profile
                        let dataForProfileUsersDatabase = ["participant": currentUser.uid]
                        let profileUsersDatabaseRef = self.db.collection("Users").document(user.uid).collection("chats").document(newDocumentID)
                        
                        profileUsersDatabaseRef.setData(dataForProfileUsersDatabase) { (error) in
                            if error != nil {
                                print("We have an error when saving chat for profile User: \(error?.localizedDescription ?? "No error")")
                            }
                        }
                        
                        self.performSegue(withIdentifier: "toNewMessage", sender: chat)
                        
                    } else {    // Go to the existing chat
                        if let document = querySnapshot?.documents.last {
                            
                            let chat = Chat()
                            let documentID = document.documentID
                            
                            chat.documentID = documentID
                            chat.participant = user
                            
                            self.performSegue(withIdentifier: "toNewMessage", sender: chat)
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toUserSegue" {
            if let choosenUser = sender as? User {
                if let nextVC = segue.destination as? UserFeedTableViewController{
                    nextVC.userOfProfile = choosenUser
                    nextVC.currentState = .friendOfCurrentUser
                }
            }
        }
        
        if segue.identifier == "toNewMessage" {
            if let chosenChat = sender as? Chat {
                if let chatVC = segue.destination as? ChatViewController {
                    chatVC.chat = chosenChat
                }
            }
        }
        
    }
    
}

protocol RequestDelegate {
    func acceptInvitation(user: User)
    func declineInvitation(user: User)
    func editButtonTapped(friend: Friend)
}

class FriendRequestCell: UITableViewCell {
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var acceptLabel: UILabel!
    
    @IBOutlet weak var editButton: DesignableButton!
    
    var friendObject: Friend!
    var delegate: RequestDelegate?
    
    func setFriend(friend: Friend) {
        friendObject = friend
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        delegate?.editButtonTapped(friend: friendObject)
    }
    
    @IBAction func acceptedTapped(_ sender: Any) {
        stackView.isHidden = true
        acceptLabel.isHidden = false
        acceptLabel.text = NSLocalizedString("friendship_allowed_label", comment: "accepted")
        acceptLabel.backgroundColor = UIColor(red:0.36, green:0.70, blue:0.37, alpha:1.0)
        acceptLabel.layer.cornerRadius = 5
        acceptLabel.clipsToBounds = true
        if let user = friendObject.user {
            delegate?.acceptInvitation(user: user)
        }
    }
    
    @IBAction func declinedTapped(_ sender: Any) {
        stackView.isHidden = true
        acceptLabel.isHidden = false
        acceptLabel.text = NSLocalizedString("friendship_declined_label", comment: "declined")
        acceptLabel.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
        acceptLabel.layer.cornerRadius = 5
        acceptLabel.clipsToBounds = true
        if let user = friendObject.user {
            delegate?.declineInvitation(user: user)
        }
    }
}


class Friend {
    var user: User?
    var accepted = false
    var requestedAt = ""
    var documentID = ""
}
