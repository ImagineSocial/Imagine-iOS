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
    
    var badgeValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getChats()
    }
    
    func setTabBarBadge() {
        if let tabItems = tabBarController?.tabBar.items {
            let tabItem = tabItems[1] //Chats
            if badgeValue != 0 {
                tabItem.badgeValue = String(badgeValue)
            }
        }
    }
    
    
    func getChats() {
        if let user = Auth.auth().currentUser {
            currentUserUid = user.uid
            let chatsRef = db.collection("Users").document(user.uid).collection("chats")
            chatsRef.getDocuments { (snapshot, error) in
                if let error = error {
                    print("We have an error within the chats: \(error.localizedDescription)")
                } else {
                
                    for document in snapshot!.documents {
                        let documentData = document.data()
                        
                        guard let participant = documentData["participant"] as? String else { continue }

                        let chat = Chat()
                        chat.documentID = document.documentID
                        chat.participant.userUID = participant
                        if let lastMessageID = documentData["lastReadMessage"] as? String {
                            chat.lastReadMessageUID = lastMessageID
                        }
                        
                        self.chatsList.append(chat)
                    }
                    self.firebaseListener()
                }
            }
            
        } else {
            // Nobody logged In
        }
    }
    
    func firebaseListener() {
        for chat in chatsList {
            
            let chatsRef = db.collection("Chats").document(chat.documentID).collection("threads").order(by: "sentAt", descending: true).limit(to: 1)
            
            chatsRef.addSnapshotListener { (snapshot, error) in
                if let error = error {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    
                    // Delete an empty Chat : Empty Chats happen when you start a new chat but dont send anything
                    if snapshot!.documentChanges.count == 0 {
                        
                        self.chatsList.removeAll{$0.documentID == chat.documentID}
                        
                        if let currentUserUid = self.currentUserUid {
                            let emptyChatRef = self.db.collection("Users").document(currentUserUid).collection("chats").whereField("documentID", isEqualTo: chat.documentID).limit(to: 1)
                            
                            emptyChatRef.getDocuments(completion: { (querySnap, err) in
                                if let err = err {
                                    print("We hava an error getting Documents: \(err.localizedDescription)")
                                } else {
                                    for document in querySnap!.documents {
                                        document.reference.delete()
                                        
                                        print("Delete empty Chat")
                                    }
                                }
                            })
                        }
                        
                        // Get the chat's last messages
                    } else {
                        snapshot!.documentChanges.forEach({ (change) in
                            // Chck if the last Sent message in this chat is equal to the lastReadMessageUID saved in the users database. If not the functions checks how many messages there actually are
                            if change.document.documentID != chat.lastReadMessageUID {
                                self.getCountOfUnreadMessages(chat: chat)
                            }
                            
                            let docData = change.document.data()
                            
                            chat.lastMessage = docData["body"] as? String ?? ""
                            chat.lastMessageSender = docData["userID"] as? String ?? ""
                            
                            if let lastMessageDate = docData["sentAt"] as? Timestamp {
                                
                                chat.lastMessageSentAt = lastMessageDate.dateValue().formatRelativeString()
                                chat.lastMessageDate = lastMessageDate.dateValue()  // For sorting
                            }
                        })
                    }
                    self.loadUsers()
                }
            }
        }
    }
    
    func getCountOfUnreadMessages(chat:Chat) {
        
        let chatsRef = self.db.collection("Chats").document(chat.documentID).collection("threads").order(by: "sentAt", descending: true)
        
        // Already been in this chat at least once
        if let lastReadMessage = chat.lastReadMessageUID {
            
            let lastReadMessageDoc = db.collection("Chats").document(chat.documentID).collection("threads").document(lastReadMessage)
            
            lastReadMessageDoc.getDocument { (document, error) in
                if let error = error {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    let endingChatsRef = chatsRef.end(beforeDocument: document!)
                    
                    endingChatsRef.getDocuments(completion: { (snap, error) in
                        
                        if let error = error {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            let unreadMessageCount = snap!.documents.count
                           
                            
                            chat.unreadMessages = unreadMessageCount
                            self.badgeValue = 0
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        } else {
            // New chat, not a lastReadMessageUID set
            chatsRef.getDocuments { (snap, error) in
                if let error = error {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    let unreadMessageCount = snap!.documents.count
                    
                    chat.unreadMessages = unreadMessageCount
                    
                    self.badgeValue = 0
                    self.tableView.reloadData()
                    
                }
            }
        }
    }
    
    
  
    
    func loadUsers() {
        
        chatsList = chatsList.sorted(by: { ($0.lastMessageDate ?? .distantPast) > ($1.lastMessageDate ?? .distantPast) })
        
        for chat in chatsList {
            // User Daten raussuchen
            let userRef = db.collection("Users").document(chat.participant.userUID)
            
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        
                        chat.participant.name = docData["name"] as? String ?? ""
                        chat.participant.surname = docData["surname"] as? String ?? ""
                        chat.participant.imageURL = docData["profilePictureURL"] as? String ?? ""
                        
                        self.badgeValue = 0
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
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return chatsList.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as? ChatCell {
            
            let chat = chatsList[indexPath.row]
            
            if chat.unreadMessages != 0 {
                self.badgeValue = badgeValue+chat.unreadMessages
                cell.unreadMessages.text = String(chat.unreadMessages)
                cell.unreadMessages.isHidden = false
                cell.unreadMessageView.isHidden = false
            } else {
                cell.unreadMessages.isHidden = true
                cell.unreadMessageView.isHidden = true
            }
            
            
            cell.nameLabel.text = "\(chat.participant.name) \(chat.participant.surname)"
            
            if let currentUserUid = currentUserUid {
                if currentUserUid == chat.lastMessageSender {
                    cell.lastMessage.text = "Du: \(chat.lastMessage)"
                } else {
                    cell.lastMessage.text = "\(chat.participant.name): \(chat.lastMessage)"
                }
            }
            
            cell.lastMessageDateLabel.text = chat.lastMessageSentAt
            
            cell.profilePictureImageView.layer.cornerRadius = cell.profilePictureImageView.frame.width/2
            cell.profilePictureImageView.layoutIfNeeded()
            
            if let url = URL(string: chat.participant.imageURL) {
                cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
            }
            
            self.setTabBarBadge()
            return cell
        }
        
        // Configure the cell...
        
        return UITableViewCell()
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chatsList[indexPath.row]
        performSegue(withIdentifier: "toChatSegue", sender: chat)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
    
    
    @IBAction func newMessage(_ sender: Any) {
        performSegue(withIdentifier: "toFriendsSegue", sender: nil)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatSegue" {
            if let chosenChat = sender as? Chat {
                if let chatVC = segue.destination as? ChatViewController {
                    chatVC.chatSetting = .normal
                    chatVC.chat = chosenChat
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

class ChatCell : UITableViewCell {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var unreadMessages: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var unreadMessageView: DesignablePopUp!
    @IBOutlet weak var lastMessageDateLabel: UILabel!
    
}

class Chat {
    var participant = User()
    var documentID = ""
    var unreadMessages = 0
    var lastMessage = ""
    var lastMessageSender = ""
    var lastMessageSentAt = ""
    var lastMessageDate: Date?  // To sort the Chats
    var lastReadMessageUID :String?
}
