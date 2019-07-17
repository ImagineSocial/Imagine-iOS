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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getChats()
        
    }
    
    
    func getChats() {
        if let user = Auth.auth().currentUser {
            currentUserUid = user.uid
            let chatsRef = db.collection("Users").document(user.uid).collection("chats")
            
            chatsRef.getDocuments { (snapshot, error) in
                if error == nil {
                    
                    for document in snapshot!.documents {
                        let documentData = document.data()
                        
                        guard let participant = documentData["participant"] as? String,
                            let documentID = documentData["documentID"] as? String
                            
                            else {
                                return
                        }
                        
                        let chat = Chat()
                        chat.documentID = documentID
                        chat.participant.userUID = participant
                        
                        self.chatsList.append(chat)
                    }
                    
//                    self.loadUsers()
                    self.getLastMessage()
                    
                } else {
                    print("We have an error within the chats: \(error?.localizedDescription)")
                }
            }
            
        } else {
            // Nobody locked In
        }
    }
    
    func getLastMessage() {
        for chat in chatsList {
            // Last Message raussuchen
            let chatRef = db.collection("Chats").document(chat.documentID).collection("threads").order(by: "sentAt", descending: true).limit(to: 1)
            
            chatRef.getDocuments(completion: { (snapshot, err) in
                
                if snapshot!.documents.count == 0 {
                    // Delete an empty Chat : Empty Chats happen when you start a new chat but dont send anything
                    
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
                    
                }
                
                for document in snapshot!.documents {
                    let docData = document.data()
                    
                    chat.lastMessage = docData["body"] as? String ?? ""
                    chat.lastMessageSender = docData["userID"] as? String ?? ""
                    
                    if let lastMessageDate = docData["sentAt"] as? Timestamp {
                        
                        chat.lastMessageSentAt = lastMessageDate.dateValue().formatRelativeString()
                        chat.lastMessageDate = lastMessageDate.dateValue()  // For sorting
                        
                        
                    }
                    
                    
                }
                self.loadUsers()
                
                
                if let err = err {
                    print("Wir haben einen Error beim User: \(err.localizedDescription)")
                }
            })
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
}
