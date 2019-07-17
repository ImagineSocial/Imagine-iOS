//
//  FriendsTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 02.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore


// Combine the two different friend cells
class FriendsTableViewController: UITableViewController, RequestDelegate {
    
    
    var friendsList = [Friend]()
    let db = Firestore.firestore()
    var isNewMessage = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFriends()
        
    }
    
    func getFriends() {
        
        if let user = Auth.auth().currentUser {
            let friendsRef = db.collection("Users").document(user.uid).collection("friends")
            
            friendsRef.order(by: "accepted", descending: false) // Requests on top
            
            friendsRef.getDocuments { (snapshot, error) in
                
                if error != nil {
                    print("We have an error when we fetch the friends: ", error?.localizedDescription ?? "No error")
                }
                
                for document in snapshot!.documents {
                    
                    let documentID = document.documentID
                    let documentData = document.data()
                    
                    guard let userUID = documentData["userUID"] as? String,
                        let requestedAt = documentData["requestedAt"] as? Timestamp,
                        let accepted = documentData["accepted"] as? Bool
                        else {
                            return
                    }
                    let friend = Friend()
                    
                    friend.user.userUID = userUID
                    friend.accepted = accepted
                    friend.requestedAt = HandyHelper().getStringDate(timestamp: requestedAt)
                    friend.documentID = documentID
                    
                    self.friendsList.append(friend)
                }
                self.loadUsers()
                
            }
        }
    }
    
    func loadUsers() {
        for friend in friendsList {
            // User Daten raussuchen
            let userRef = db.collection("Users").document(friend.user.userUID)
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        friend.user.name = docData["name"] as? String ?? ""
                        friend.user.surname = docData["surname"] as? String ?? ""
                        friend.user.imageURL = docData["profilePictureURL"] as? String ?? ""
                        
                        
                        self.tableView.reloadData()
                    }
                }
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "No error")")
                }
            })
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // 2 Sections later: One for requested, one for friends
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friendsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend = friendsList[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "FriendRequestCell", for: indexPath) as? FriendRequestCell {
            
            cell.delegate = self
            cell.setFriend(friend: friend)
            
            cell.acceptLabel.isHidden = true
            cell.nameLabel.text = "\(friend.user.name) \(friend.user.surname)"
            
            
            cell.profilePictureImageView.layer.cornerRadius = 2
            if let url = URL(string: friend.user.imageURL) {
                cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
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
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friend = friendsList[indexPath.row]
        
        if isNewMessage {
            goToChatTapped(friend: friend)
        } else {
            performSegue(withIdentifier: "toUserSegue", sender: friend.user.userUID)
        }
    }
    
    
    func acceptInvitation(friend: Friend) {
        if let user = Auth.auth().currentUser {
            let requestRef = db.collection("Users").document(user.uid).collection("friends").document(friend.documentID)
            
            requestRef.updateData(["accepted": true])   // Accept and change the database of the current User
            
            friend.accepted = true
            
            let data: [String:Any] = ["accepted": true, "requestedAt" : Timestamp(date: Date()), "userUID": user.uid]
            
            let friendRef = db.collection("Users").document(friend.user.userUID).collection("friends").document()
            
            friendRef.setData(data) { (error) in    // Change Database of the inviter
                if error != nil {
                    print("We have an errror while trying to add a friend: \(error?.localizedDescription ?? "No Error")")
                }
            }
            
//            self.tableView.reloadData()
        }
    }
    
    func declineInvitation(friend: Friend) {
        if let user = Auth.auth().currentUser {
            let requestRef = db.collection("Users").document(user.uid).collection("friends").document(friend.documentID)
            //            requestRef.setData(["declined": true], mergeFields:["declined"])
            requestRef.delete()
            
            
//            if let index = friendsList.index(where: {$0.documentID == friend.documentID}) {
//                self.friendsList.remove(at: index)
//
//                self.tableView.reloadData()
//            }
        }
    }
    
    lazy var settingsLauncher: SettingsLauncher = {
        let launcher = SettingsLauncher(type: .friendsTableView)
        launcher.FriendsTableVC = self
        return launcher
    }()
    
    func showControllerForSetting(setting: Setting, friend: Friend) {
        switch setting.settingType {
        case .chatWithUser:
            goToChatTapped(friend: friend)
        case .blockUser:
            print("Kommt noch!!")
        default:
            print("Nichts")
//            let dummySettingsViewController = UIViewController()
//            dummySettingsViewController.view.backgroundColor = UIColor.white
//            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
//            navigationController?.pushViewController(dummySettingsViewController, animated: true)
        }
        
    }
    
    func editButtonTapped(friend: Friend) {
        settingsLauncher.showSettings(for: friend)
    }
    
    
    
    func goToChatTapped(friend: Friend) {
        let user = friend.user
        
        if let currentUser = Auth.auth().currentUser {
            // Check if there is already a chat
            let chatRef = db.collection("Users").document(currentUser.uid).collection("chats").whereField("participant", isEqualTo: user.userUID).limit(to: 1)
            
            chatRef.getDocuments { (querySnapshot, error) in
                if error != nil {
                    print("We have an error downloading the chat: \(error?.localizedDescription ?? "no error")")
                } else {
                    if querySnapshot!.isEmpty { // Create a new chat
                        
                        let chat = Chat()
                        chat.participant = user
                        
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
                        let profileUsersDatabaseRef = self.db.collection("Users").document(user.userUID).collection("chats").document()
                        
                        profileUsersDatabaseRef.setData(dataForProfileUsersDatabase) { (error) in
                            if error != nil {
                                print("We have an error when saving chat for profile User: \(error?.localizedDescription ?? "No error")")
                            }
                        }
                        
                        self.performSegue(withIdentifier: "toNewMessage", sender: chat)
                        
                    } else {    // Go to the existing chat
                        if let document = querySnapshot?.documents.last {
                            let chat = Chat()
                            
                            let documentData = document.data()
                            
                            if let documentID = documentData["documentID"] as? String {
                                
                                chat.documentID = documentID
                                chat.participant = user
                                
                                self.performSegue(withIdentifier: "toNewMessage", sender: chat)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? UserFeedTableViewController {
            if let OPUID = sender as? String {
                nextVC.userUID = OPUID
            } else {
                print("Irgendwas will der hier nicht übertragen")
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
    func acceptInvitation(friend: Friend)
    func declineInvitation(friend: Friend)
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
        acceptLabel.text = "Ihr seid nun befreundet!"
        acceptLabel.backgroundColor = UIColor(red:0.36, green:0.70, blue:0.37, alpha:1.0)
        acceptLabel.layer.cornerRadius = 5
        acceptLabel.clipsToBounds = true
        delegate?.acceptInvitation(friend: friendObject)
    }
    
    @IBAction func declinedTapped(_ sender: Any) {
        stackView.isHidden = true
        acceptLabel.isHidden = false
        acceptLabel.text = "Anfrage abgelehnt"
        acceptLabel.backgroundColor = UIColor(red:1.00, green:0.54, blue:0.52, alpha:1.0)
        acceptLabel.layer.cornerRadius = 5
        acceptLabel.clipsToBounds = true
        delegate?.declineInvitation(friend: friendObject)
    }
}


class Friend {
    var user = User()
    var accepted = false
    //    var declined = false
    var requestedAt = ""
    var documentID = ""
}
