//
//  PostCommentChatViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Photos
import Firebase
import FirebaseFirestore
import MessengerKit

class PostCommentChatViewController: MSGMessengerViewController {
    
    
    private let db = Firestore.firestore()
    var post = Post()
    var currentUser :MSGUser?
    var currentUserUid = ""
    var commentCount = 0
    
    let tim = ChatUser(displayName: "Tim", avatar: UIImage(named: "default-user"), avatarURL: nil, isSender: false)
    
    var id = 0
    

    // Messages
    
    lazy var messages: [[MSGMessage]] = {
        return [ [// INdex out of range
                MSGMessage(id: 1, body: .text("Was hast du zu diesem interessanten Post zu sagen?"), user: tim, sentAt: Date()),
                ] ]
    }()
    
    var fetchedMessages: [MSGMessage] = { return [] }() // ZwischenMessages damit ich die sortieren kann, macht Firebase nicht richti
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        print("Jetzt im PostCommentChatViewController")
        // MSGMessenger
        dataSource = self
        delegate = self
        
        firebaseListener()
        setCurrentUser()
    }
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCurrentUser() {
        if let uid = Auth.auth().currentUser?.uid {
            currentUserUid = uid
            PostHelper().getChatUser(uid: uid, sender: true) { (user) in
                self.currentUser = user
            }
        }
    }
    
    
    // Firebase Listener
    func firebaseListener() {
        
        let reference = db.collection("Comments").document(post.documentID).collection("threads").order(by: "sentAt", descending: false)
        
        // Guckt ob sich was verändert
        reference.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return      // Wenn squerySnapshot nicht snapshot ist
            }
            print("Error:", error?.localizedDescription)
            
            let snapCount = snapshot.documentChanges.count
            
            // Alles neue (Am anfang alle) werden jetzt weitergeleitet als "change" document
            snapshot.documentChanges.forEach { change in
                self.handlingChanges(incomingChanges: snapCount, change: change)
            }
        }
        
    }
    
    
    func handlingChanges(incomingChanges: Int, change: DocumentChange) {
       
        let doc = change.document
        let docData = doc.data()
        var sender = false
        guard let currentUser = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let id = docData["id"] as? Int,
            let body = docData["body"] as? String,
            let sentAtTimestamp = docData["sentAt"] as? Timestamp,
            let userUID = docData["userID"] as? String
            else {
                return    // Falls er das nicht zuordnen kann
        }
        
        if userUID == currentUser {
            sender = true   // Die Nachricht stammt von ihm
        }
        
        let sentDate:Date = sentAtTimestamp.dateValue()
        
        PostHelper().getChatUser(uid: userUID, sender: sender, user: { (user) in
            
            let message = MSGMessage(id: id, body: .text(body), user: user, sentAt: sentDate)
            self.fetchedMessages.append(message)
            
            if self.fetchedMessages.count == incomingChanges {
                self.commentCount = self.commentCount+incomingChanges
                
                // Nach Datum sortieren, hat Firebase nicht richtig gemacht
                self.fetchedMessages.sort(by: { $0.sentAt.compare($1.sentAt) == .orderedAscending })
                self.insert(self.fetchedMessages)
                self.fetchedMessages.removeAll()    // Alle Löschen, sind dann ja in messages
                
                self.post.commentCount = self.commentCount  // Das Post Objekt updaten
            }
        })
    }
    
        
    
    
    func saveInFirebase(bodyString: String, message: MSGMessage) {
        
        let reference = db.collection("Comments").document(post.documentID).collection("threads")
    
        
        let data : [String: Any] = ["body": bodyString, "id": message.id, "sentAt": getDate(), "userID": currentUserUid]
        
        reference.addDocument(data: data) { error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
        }
    }
    
    
    // Habe ich schonmal, kann ich mir sparen irgendwie
    func getDate() -> Timestamp {
        
        let date = Date()
        
        return Timestamp(date: date)
    }
    
    
    // MSGMessengerStuff
    
//    override var style: MSGMessengerStyle {
//        let style = MessengerKit.Styles.iMessage
//        return style
//    }
    
    override func inputViewPrimaryActionTriggered(inputView: MSGInputView) {    // Wenn jemand send gedrückt hat
        
        
        let body: MSGMessageBody =  (inputView.message.containsOnlyEmoji && inputView.message.count < 5) ? .emoji(inputView.message) : .text(inputView.message)
        
        // inputView.message ist die Nachricht
        if let user = currentUser {
            let message = MSGMessage(id: id+1, body: body, user: user, sentAt: Date())
            
            if currentUserUid != "" {   // Falls man nur Gast ist
                saveInFirebase(bodyString: inputView.message, message: message)
            }
            
            // Brauche ich nicht, weil Firebase Listener das macht!! insert(message)
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
            print(self.messages, "Messages!!!")
        })
        
    }
}

// MARK: - MSGDataSource

extension PostCommentChatViewController: MSGDataSource {
    
    func numberOfSections() -> Int {        // Section ist ein Batzen an Nachrichten
//        print("1")
        return messages.count
    }
    
    func numberOfMessages(in section: Int) -> Int {
//        print("2")
        return messages[section].count
    }
    
    func message(for indexPath: IndexPath) -> MSGMessage {
//        print("3")
//        print(indexPath.section, indexPath.item)
        return messages[indexPath.section][indexPath.item]  // DIe einzelnen Nachrichten in einem Batzen
    }
    
    func footerTitle(for section: Int) -> String? {
//        print("4")
        var stringDate = ""
        if let date = messages[section].first?.sentAt {
            
            // Datum vom Timestamp umwandeln
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MM yyyy HH:mm"
            stringDate = formatter.string(from: date)
        }
        
        return stringDate
    }
    
    func headerTitle(for section: Int) -> String? {
//        print("5")
        return messages[section].first?.user.displayName
    }
    
}

// MARK: - MSGDelegate
extension PostCommentChatViewController: MSGDelegate {
    
    /// Called when a link is tapped in a message
    func linkTapped(url: URL) {
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

