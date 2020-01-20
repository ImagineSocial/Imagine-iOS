//
//  ChatsTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

//Get Last Message!
class ChatsTableViewController: UITableViewController {
    
    let db = Firestore.firestore()
    var chatsList = [Chat]()
    var currentUserUid:String?
    var loggedIn = false
    
    
    var initialFetch = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = false
        if #available(iOS 13.0, *) {
            self.navigationController?.view.backgroundColor = .systemBackground
        } else {
            self.navigationController?.view.backgroundColor = .white
        }
        
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: "NibBlankCell")
        
        getChats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Does not get reloaded after you have logged In again!
        // Wont disappear when not logged in anymore
        
        if Auth.auth().currentUser == nil && loggedIn == true {
            self.chatsList.removeAll()
            self.tableView.reloadData()
        } else if Auth.auth().currentUser != nil && loggedIn == false {
            self.getChats()
        }
//        tableView.reloadData()
    }
    
    
    
    /*
     
     --Initial Fetch --
     1. getChats -> participant & documentID from each chat of the user
     2. getUnreadMessages -> Just the count of the unread messages of each chat and listener set
     3. loadUsers -> the participant is fetched with name and Picture
     4. getLastMessage -> Last message of each chat is fetched
     
     -- New Message --
     1. getUnreadMessages -> Listener gets called
     2. getNewMessage -> Fetch Last Message and reload TableView
     
     */
    
    
    func getChats() {   // Get participant and every documentID of every chat that the user has
        if let user = Auth.auth().currentUser {
            self.loggedIn = true
            if chatsList.count == 0 {
                self.view.activityStartAnimating()
            }
            currentUserUid = user.uid
            
            let chatsRef = db.collection("Users").document(user.uid).collection("chats")
            
            chatsRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("We have an error within the chats: \(error.localizedDescription)")
                } else {
                    if snapshot!.documents.count != self.chatsList.count {  // New message or first time
                        self.chatsList.removeAll()
                        
                        for document in snapshot!.documents {
                            let documentData = document.data()
                            
                            guard let participant = documentData["participant"] as? String else { continue }
                            
                            let chat = Chat()
                            chat.documentID = document.documentID
                            chat.participant.userUID = participant
                            if let lastMessageID = documentData["lastReadMessage"] as? String {
                                chat.lastMessage.uid = lastMessageID
                            }
                            
                            self.chatsList.append(chat)
                        }
                        self.getUnreadMessages()
                        self.getLastMessages()
                    } else {
                        print("No new Chats")
                        self.view.activityStopAnimating()
                    }
                }
            }
        } else {
            self.chatsList.removeAll()
            self.tableView.reloadData()
            self.loggedIn = false
        }
    }
    
    
    
    func getUnreadMessages() {
        if let user = Auth.auth().currentUser {
            let notificationRef = db.collection("Users").document(user.uid).collection("notifications").whereField("type", isEqualTo: "message")
            
            notificationRef.addSnapshotListener { (snap, err) in    // Get messageNotifications
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {                    
                    if let snap = snap {
//                        self.updateTabBarBadge(value: snap.documents.count)
                        
                        snap.documentChanges.forEach { (change) in  // One Message Notification
                            if change.type == DocumentChangeType.added {    // Just get it if it is added
                                
                                let data = change.document.data()
                                
                                if let chatID = data["chatID"] as? String {
                                    for chat in self.chatsList {
                                        if chatID == chat.documentID {  // Found the chat for the notification
                                            let unreadCount = chat.unreadMessages
                                            chat.unreadMessages = unreadCount+1 // Add one for unreadMessageCount
                                            
                                            if !self.initialFetch {
                                                print("New Message")
                                                if let messageID = data["messageID"] as? String {
                                                    self.getNewMessage(chat: chat, messageID: messageID)
                                                }
                                            } else {
                                                print("First Fetch")
                                            }
                                        }
                                    }
                                }
                            } else if change.type == DocumentChangeType.removed {
                                print("Got removed")
                            }
                        }
                        self.initialFetch = false
                    }
                }
            }
        }
    }
    
    
    func getNewMessage(chat: Chat, messageID: String) {
        let messageRef = db.collection("Chats").document(chat.documentID).collection("threads").document(messageID)
        messageRef.getDocument { (doc, err) in
            if let error = err {
                print("We have an error: ", error.localizedDescription)
            } else {
                if let document = doc {
                    
                    if let data = document.data() {
                        if let body = data["body"] as? String, let sentAt = data["sentAt"] as? Timestamp, let userID = data["userID"] as? String {
                            
                            chat.lastMessage.message = body
                            chat.lastMessage.sender = userID
                            let date = sentAt.dateValue()
                            chat.lastMessage.sentAtDate = date
                            chat.lastMessage.sentAt = date.formatRelativeString()
                            chat.lastMessage.uid = document.documentID
                            
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    func getLastMessages() {
        for chat in chatsList {
            let messageRef = db.collection("Chats").document(chat.documentID).collection("threads").order(by: "sentAt", descending: true).limit(to: 1)//I guess
            
            messageRef.getDocuments { (snapshot, err) in
                if let error = err {
                    print("We have an error: ", error.localizedDescription)
                } else {
                    if let snap = snapshot {
                        if snap.documents.count == 0 {
                            self.deleteChat(chatID: chat.documentID)
                        }
                        for document in snap.documents {
                            let data = document.data()
                            if let body = data["body"] as? String, let sentAt = data["sentAt"] as? Timestamp, let userID = data["userID"] as? String {
                                
                                chat.lastMessage.message = body
                                chat.lastMessage.sender = userID
                                let date = sentAt.dateValue()
                                chat.lastMessage.sentAtDate = date  // to sort the chats
                                chat.lastMessage.sentAt = date.formatRelativeString()
                                chat.lastMessage.uid = document.documentID
                            }
                        }
                        // Not optimal because it gets called each time
                        self.chatsList = self.chatsList.sorted(by: { ($0.lastMessage.sentAtDate ?? .distantPast) > ($1.lastMessage.sentAtDate ?? .distantPast) })
                    }
                }
            }
        }
        let postHelper = PostHelper()
        //Get Friends of the current User to check when they load the user of the chats
        postHelper.getTheUsersFriend {friends in
            self.loadUsers(friends: friends)
        }
        
    }
    
    func deleteChat(chatID: String) {
        self.chatsList.removeAll{$0.documentID == chatID}
        
        print("Trying to delete chat with ID: ", chatID)
        
        if let currentUserUid = self.currentUserUid {
            let emptyChatRef = self.db.collection("Users").document(currentUserUid).collection("chats").document(chatID)

            emptyChatRef.getDocument(completion: { (doc, err) in
                if let err = err {
                    print("We hava an error getting Documents: \(err.localizedDescription)")
                } else {
                    if let document = doc {
                        document.reference.delete()
                        print("Delete empty Chat")
                    }
                }
            })
        }
    }
    
    
    func loadUsers(friends: [String]) {
        
        for chat in chatsList {
            // User Daten raussuchen
            let userRef = db.collection("Users").document(chat.participant.userUID)
            
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        if friends.contains(chat.participant.userUID) {
                            // Is a friend of the current User
                            let name = docData["name"] as? String ?? ""
                            let surname = docData["surname"] as? String ?? ""
                            
                            chat.participant.displayName = "\(name) \(surname)"
                        } else {
                            chat.participant.displayName = docData["name"] as? String ?? ""
                        }
                        chat.participant.imageURL = docData["profilePictureURL"] as? String ?? ""
                        
                        self.tableView.reloadData()
                        self.view.activityStopAnimating()
                    }
                }
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "No error")")
                }
            })
        }
        tableView.reloadData()
    }
    
    
    // MARK: - Table view data source
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        if chatsList.count == 0 {
            tableView.separatorStyle = .none
            return 1
        } else {
            tableView.separatorStyle = .singleLine
            tableView.separatorInset = UIEdgeInsets(top: 0, left: 85, bottom: 0, right: 0)
            return chatsList.count
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if chatsList.count == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NibBlankCell", for: indexPath) as? BlankContentCell {
                
                cell.type = BlankCellType.chat
                
                return cell
            }
            
            let cell = UITableViewCell()
                        
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            
            return cell
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as? ChatCell {
                
                let chat = chatsList[indexPath.row]
                
                if chat.unreadMessages != 0 {
                    cell.unreadMessages.text = String(chat.unreadMessages)
                    cell.unreadMessages.isHidden = false
                    cell.unreadMessageView.isHidden = false
                } else {
                    cell.unreadMessages.isHidden = true
                    cell.unreadMessageView.isHidden = true
                }
                
                cell.nameLabel.text = chat.participant.displayName
                
                if let currentUserUid = currentUserUid {
                    if currentUserUid == chat.lastMessage.sender {  // If you are the sender of the last message
                        cell.lastMessage.text = "Du: \(chat.lastMessage.message)"
                    } else {
                        cell.lastMessage.text = "\(chat.participant.displayName): \(chat.lastMessage.message)"
                    }
                }
                
                cell.lastMessageDateLabel.text = chat.lastMessage.sentAt
                
                cell.profilePictureImageView.layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                cell.profilePictureImageView.layoutIfNeeded()
                
                if let url = URL(string: chat.participant.imageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if chatsList.count == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            let chat = chatsList[indexPath.row]
            performSegue(withIdentifier: "toChatSegue", sender: chat)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if chatsList.count == 0 {   //
            return self.view.frame.height-100
        } else {
            return 80
        }
    }
    
    
    
    
    @IBAction func newMessage(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toFriendsSegue", sender: nil)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatSegue" {
            if let chosenChat = sender as? Chat {
                if let chatVC = segue.destination as? ChatViewController {
                    chatVC.chatSetting = .normal
                    chatVC.chat = chosenChat
                    chatVC.readDelegate = self
                }
            }
        }
        if segue.identifier == "toFriendsSegue" {
            if let friendVC = segue.destination as? FriendsTableViewController {
                friendVC.isNewMessage = true
            }
        }
    }
}

extension ChatsTableViewController : ReadMessageDelegate {
    func read() {
        self.tableView.reloadData()
    }
}

//MARK: - ChatCell

class ChatCell : UITableViewCell {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unreadMessages: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var unreadMessageView: DesignablePopUp!
    @IBOutlet weak var lastMessageDateLabel: UILabel!
    
}


//MARK: - Chat Class Declaration

class Chat {
    var participant = User()
    var documentID = ""
    var unreadMessages = 0
    var lastMessage = Message()
}

class Message {
    var message = ""
    var sender = ""
    var sentAt = ""
    var sentAtDate: Date?   // To sort the Chats
    var uid: String?
}
