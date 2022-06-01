//
//  ChatViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import MessengerKit
import FirebaseFirestore

enum chatType {
    case normal
    case new
    case community
}

protocol ReadMessageDelegate {
    func read()
}

class ChatViewController: MSGMessengerViewController {
    
    var chat: Chat?
    let malte = ChatUser(displayName: "", avatar: UIImage(named: "default-user"), avatarURL: nil, isSender: false)
    lazy var messages: [[MSGMessage]] = {
        return [ [// INdex out of range
            MSGMessage(id: 1, body: .text(NSLocalizedString("chat_security_message", comment: "not save, only for first messages")), user: malte, sentAt: Date()),
            ] ]
    }()
    var fetchedMessages: [MSGMessage] = { return [] }()
    
    private let db = FirestoreRequest.shared.db
    var reference: Query?
    var currentUserUid = ""
    var currentUser :MSGUser?
    var commentCount = 0
    var id = 2
    
    var initialFetch = true
    
    var chatSetting:chatType?
    
    var listener: ListenerRegistration?
    var readDelegate: ReadMessageDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MSGMessenger
        dataSource = self
        delegate = self
                
        setChatSettings()
        setCurrentUser()
        
        
        if let chat = chat {
            if chat.unreadMessages != 0 {
                self.deleteNotifications()
            }
        }
    }
    
    func setChatSettings() {
        switch chatSetting {
        case .normal?:
            setNavUserButton()
        case .community?:
            self.navigationItem.title = "Community Chat"
            let communityFirstMessage: [[MSGMessage]] = {
                return [ [// INdex out of range
                    MSGMessage(id: 1, body: .text("Möchtest du uns etwas fragen?"), user: malte, sentAt: Date()),
                    ] ]
            }()
            messages.removeAll()
            messages = communityFirstMessage
        case .new?:
            setNavUserButton()
            let newChatFirstMessage: [[MSGMessage]] = {
                return [ [// INdex out of range
                    MSGMessage(id: 1, body: .text(NSLocalizedString("chat_security_message", comment: "not save, only for first messages")), user: malte, sentAt: Date()),
                    ] ]
            }()
            messages.removeAll()
            messages = newChatFirstMessage
        default:
            return
        }
    }
    
    func setNavUserButton() {
        if let participant = chat?.participant {
            self.navigationItem.title = participant.displayName
            
            let button = DesignableButton()
            button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
            button.addTarget(self, action: #selector(self.toUserTapped), for: .touchUpInside)
            button.layer.masksToBounds = true
            button.imageView?.contentMode = .scaleAspectFill
            
            if let urlString = participant.imageURL, let url = URL(string: urlString) {
                do {
                    let data = try Data(contentsOf: url)
                    
                    if let image = UIImage(data: data) {
                        
                        //set image for button
                        button.setImage(image, for: .normal)
                        button.constrain(width: 35, height: 35)
                        button.layer.cornerRadius = button.frame.width/2
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
            }
            
            let barButton = UIBarButtonItem(customView: button)
            self.navigationItem.rightBarButtonItem = barButton
        }
    }
    
    
    @objc func toUserTapped() {
        if let participant = chat?.participant {
            performSegue(withIdentifier: "toUserSegue", sender: participant)
        }
    }
    
    func setCurrentUser() {
        if let uid = AuthenticationManager.shared.user?.uid {
            currentUserUid = uid
            
            self.firebaseListener()
            FirestoreRequest.shared.getChatUser(uid: uid, sender: true) { (user) in
                self.currentUser = user
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let listener = listener {
            print("Listener wird removed")
            listener.remove()
        }
    }
    
//    deinit {
//        print("Deinit")
//    }
    
    
    func firebaseListener() {
        if let chat = chat {
            let reference = db.collection("Chats").document(chat.documentID).collection("threads").order(by: "sentAt", descending: false)
            
            // Guckt ob sich was verändert
            listener = reference.addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                    return      // Wenn squerySnapshot nicht snapshot ist
                }
                
                let snapCount = snapshot.documentChanges.count
                
                if snapshot.documentChanges.isEmpty {
                    self.chatSetting = .new
                    self.setChatSettings()
                }
                
                if !self.initialFetch {
                    self.deleteNotifications()
                }
                
                // To check if there is a notification, that has to be deleted
                self.initialFetch = false
                // Alles neue (Am anfang alle) werden jetzt weitergeleitet als "change" document
                snapshot.documentChanges.forEach { change in
                    self.handlingChanges(incomingChanges: snapCount, change: change)
                }
            }
            
        
        }
        
    }
    
    
    func handlingChanges(incomingChanges: Int, change: DocumentChange) {
        
        let doc = change.document
        let docData = doc.data()
        var sender = false
        
        guard let id = docData["id"] as? Int,
            let body = docData["body"] as? String,
            let sentAtTimestamp = docData["sentAt"] as? Timestamp,
            let userUID = docData["userID"] as? String
            else {
                return    // Falls er das nicht zuordnen kann
        }
        
        if userUID == currentUserUid {
            sender = true   // Die Nachricht stammt von ihm
        }
        
        let sentDate:Date = sentAtTimestamp.dateValue()
        
        FirestoreRequest.shared.getChatUser(uid: userUID, sender: sender) { user in
            guard let user = user else {
                return
            }
            
            let message = MSGMessage(id: id, body: .text(body), user: user, sentAt: sentDate)
            self.fetchedMessages.append(message)
            
            if self.fetchedMessages.count == incomingChanges {
                self.commentCount = self.commentCount+incomingChanges
                
                // Nach Datum sortieren, hat Firebase nicht richtig gemacht
                self.fetchedMessages.sort(by: { $0.sentAt.compare($1.sentAt) == .orderedAscending })
                self.insert(self.fetchedMessages)
                
                self.fetchedMessages.removeAll()    // Alle Löschen, sind dann ja in messages
                
            }
        }
    }
    
    
    func saveInFirebase(bodyString: String, message: MSGMessage) {
        if let chat = chat {
            
            let reference = db.collection("Chats").document(chat.documentID).collection("threads").document()
                        
            let data : [String: Any] = ["body": bodyString, "id": message.id, "sentAt": Timestamp(date: Date()), "userID": currentUserUid]
            
            reference.setData(data) { (error) in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                }
            }
            
            // Has to be in line of the reference.setData instead of parallel
            self.setNotification(chat: chat, bodyString: bodyString, messageID: reference.documentID)
        }
    }
    
    func setNotification(chat: Chat, bodyString: String, messageID: String) {
        if let currentUser = currentUser, let participant = chat.participant {
            let notificationRef = db.collection("Users").document(participant.uid).collection("notifications").document()
            let notificationData: [String: Any] = ["type": "message", "message": bodyString, "name": currentUser.displayName, "chatID": chat.documentID, "sentAt": Timestamp(date: Date()), "messageID": messageID]
            
            if let chat = self.chat {
                if let user = AuthenticationManager.shared.user {
                    let message = chat.lastMessage
                    message.message = bodyString
                    message.sender = user.uid
                    message.sentAtDate = Date()
                    message.sentAt = Date().formatRelativeString()
                    message.uid = messageID
                }
            }
            
            notificationRef.setData(notificationData) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Successfully set notification")
                }
            }
        }
    }
    
    func deleteNotifications() {
        print("deletenotification")
        readDelegate?.read()    // For the tableView
        if let chat = chat {
            HandyHelper.shared.deleteNotifications(type: .message, id: chat.documentID)
        }
        if let chat = chat {
            chat.unreadMessages = 0
        }
    }
        
    
    
    override func inputViewPrimaryActionTriggered(inputView: MSGInputView) {
        
        
        let body: MSGMessageBody =  (inputView.message.containsOnlyEmoji && inputView.message.count < 5) ? .emoji(inputView.message) : .text(inputView.message)
        
        // inputView.message ist die Nachricht
        if let user = currentUser {
            let message = MSGMessage(id: id+1, body: body, user: user, sentAt: Date())
            
            if currentUserUid != "" {   // unneccessary I think
                saveInFirebase(bodyString: inputView.message, message: message)
            }
            
            // Brauche ich nicht, weil Firebase Listener das macht!! insert(message)
        } else {
            self.notLoggedInAlert()
        }
        inputView.resignFirstResponder()
    }
    
    
    // Nur zum sortieren, collectionView zum anzeigen!!! Nutze ich gerade nicht!
    override func insert(_ message: MSGMessage) {
        if message.id >= self.id {
            self.id = message.id+1
        }
        // Muss noch was wegen der ID gemacht werden Wenn nicht ich die neue Nachricht ausführe...
        
        collectionView.performBatchUpdates({
            // Hier sortiert er das in die Batzen!!!
            
            
            if let lastSection = self.messages.last, let lastMessage = lastSection.last, lastMessage.user.displayName == message.user.displayName {
                self.messages[self.messages.count - 1].append(message) // An die letzte Section anhängen
                
                let sectionIndex = self.messages.count - 1
                let itemIndex = self.messages[sectionIndex].count - 1
                self.collectionView.insertItems(at: [IndexPath(item: itemIndex, section: sectionIndex)])
                
            } else {
                self.messages.append([message])
                let sectionIndex = self.messages.count - 1
                self.collectionView.insertSections([sectionIndex])
            }
        }, completion: { (_) in
            self.collectionView.scrollToBottom(animated: true)
            self.collectionView.layoutTypingLabelIfNeeded()
        })
        
    }
    
    override func insert(_ messages: [MSGMessage], callback: (() -> Void)? = nil) {
        
        collectionView.performBatchUpdates({
            for message in messages {
                
                if message.id >= self.id {
                    self.id = message.id+1
                }
                
                if let lastSection = self.messages.last, let lastMessage = lastSection.last, lastMessage.user.displayName == message.user.displayName {
                    
                    self.messages[self.messages.count - 1].append(message)  // Wird in den Batzen des Vorgängers eingefügt, wenn er den gleichen Namen hat
                    
                    let sectionIndex = self.messages.count - 1
                    let itemIndex = self.messages[sectionIndex].count - 1
                    self.collectionView.insertItems(at: [IndexPath(item: itemIndex, section: sectionIndex)])
                    
                } else {
                    self.messages.append([message])
                    let sectionIndex = self.messages.count - 1
                    self.collectionView.insertSections([sectionIndex])
                }
            }
        }, completion: { (_) in
            self.collectionView.scrollToBottom(animated: false)
            self.collectionView.layoutTypingLabelIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                callback?()
            }
        })
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserSegue" {
            if let chosenUser = sender as? User {
                if let userVC = segue.destination as? UserFeedTableViewController {
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                }
            }
        }
    }
}



// MARK: - MSGDataSource

extension ChatViewController: MSGDataSource {
    
    func numberOfSections() -> Int {        // Section ist ein Batzen an Nachrichten
        return messages.count
    }
    
    func numberOfMessages(in section: Int) -> Int {
        return messages[section].count
    }
    
    func message(for indexPath: IndexPath) -> MSGMessage {
        
        return messages[indexPath.section][indexPath.item]  // DIe einzelnen Nachrichten in einem Batzen
    }
    
    func footerTitle(for section: Int) -> String? {
        var stringDate = ""
        if let date = messages[section].first?.sentAt {
            
            // Datum vom Timestamp umwandeln
            let formatter = DateFormatter()
            let language = LanguageSelection().getLanguage()
            if language == .english {
                formatter.dateFormat = "MM/dd/yyyy HH:mm"
            } else {
                formatter.dateFormat = "dd.MM.yyyy HH:mm"
            }
            stringDate = formatter.string(from: date)
        }
        
        return stringDate
    }
    
    func headerTitle(for section: Int) -> String? {
        return messages[section].first?.user.displayName
    }
    
}

// MARK: - MSGDelegate
extension ChatViewController: MSGDelegate {
    
    /// Called when a link is tapped in a message
    func linkTapped(url: URL) {
        UIApplication.shared.open(url)
        print("Link tapped:", url)
    }
    
    /// Called when an avatar is tapped
    func avatarTapped(for user: MSGUser) {
        print("Avatar tapped:", user)
    }
    
    /// Called when a message is tapped
    func tapReceived(for message: MSGMessage) {
        print("Tapped: ", message)
    }
    
    /// Called when a message is long pressed
    func longPressReceieved(for message: MSGMessage) {
        print("Long press:", message)
    }
    
    /// When a link is tapped MessengerKit will first ask if
    /// `SFSafariViewController` should be presented.
    func shouldDisplaySafari(for url: URL) -> Bool {
        return true
    }
    
    /// Should a link not be of the http scheme this method
    /// will be called i.e. mail, tel etc.
    func shouldOpen(url: URL) -> Bool {
        return true
    }
    
}


