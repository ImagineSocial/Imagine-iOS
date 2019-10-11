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
import FirebaseAuth
import MessengerKit

class PostCommentChatViewController: MSGMessengerViewController {
    
    
    private let db = Firestore.firestore()
    var post = Post()
    let postHelper = PostHelper()
    var currentUser :MSGUser?
    var currentUserUid = ""
    var commentCount = 0
    var allowedToComment = true
    var listener :ListenerRegistration?
    
    public var hasntSwipedYet = true
    
    let tim = ChatUser(displayName: "Tim", avatar: UIImage(named: "default-user"), avatarURL: nil, isSender: false)
    
    var id = 2
    
    // Messages
    lazy var messages: [[MSGMessage]] = {
        return [ [// INdex out of range
                MSGMessage(id: 1, body: .text("Was hast du zu diesem interessanten Post zu sagen?"), user: tim, sentAt: Date()),
                ] ]
    }()
    
    var fetchedMessages: [MSGMessage] = { return [] }() // ZwischenMessages damit ich die sortieren kann, macht Firebase nicht richtig
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MSGMessenger
        dataSource = self
        delegate = self
        
        firebaseListener()
        setCurrentUser()
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipedToRight))
        swipeGesture.direction = .right
        self.view.addGestureRecognizer(swipeGesture)
        
        setBarButtonItem()
        
        if hasntSwipedYet {
            showSwipeView()
        }
        
        if post.toComments {    // Comes from SideMenu Notification
            self.deleteNotification()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let listener = listener {
            listener.remove()
            print("remove listener")
        }
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
            checkIfTheCurrentUserIsBlocked()
            
            currentUserUid = uid
            postHelper.getChatUser(uid: uid, sender: true) { (user) in
                self.currentUser = user
            }
        }
    }
    
    func checkIfTheCurrentUserIsBlocked() {
        if post.user.userUID != "" {
            if let user = Auth.auth().currentUser {
                db.collection("Users").document(post.user.userUID).getDocument { (document, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let docData = document!.data() {
                            if let blocked = docData["blocked"] as? [String] {
                                for id in blocked {
                                    if user.uid == id {
                                        self.allowedToComment = false
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                post.getUser()
                checkForData()
            }
        }
    }
    
    var index = 0
    func checkForData() {
        
        if index < 20 {
            if post.user.userUID != "" {
                self.checkIfTheCurrentUserIsBlocked()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.index+=1
                    self.checkForData()
                }
            }
        } else {
            // Alert oder so
        }
    }
    
    func deleteNotification() {
        HandyHelper().deleteNotifications(type: .comment, id: post.documentID)
    }
    
    //MARK: - BarButton
    func setBarButtonItem() {
        let backButton = DesignableButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Zum Post", for: .normal)
        backButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
        backButton.setTitleColor(UIColor(red:0.33, green:0.47, blue:0.65, alpha:1.0), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        let rightBarButton = UIBarButtonItem(customView: backButton)
        self.navigationItem.leftBarButtonItem = rightBarButton
    }
    
    @objc func backButtonTapped() {
        UIView.transition(with: self.navigationController!.view, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            self.navigationController?.popViewController(animated: true)
        }, completion: nil)
    }
    
    @objc func swipedToRight() {
        backButtonTapped()
        
        hasntSwipedYet = false
    }
    
    func showSwipeView() {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let layer = view.layer
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 20
        view.clipsToBounds = true
        view.layoutIfNeeded()
        
        view.backgroundColor = .black
        view.alpha = 0.2
        
        self.view.addSubview(view)
        view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 250).isActive = true
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        view.widthAnchor.constraint(equalToConstant: 40).isActive = true
        let leadingConstraint = view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 75)
        leadingConstraint.isActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            leadingConstraint.constant = 300
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                view.alpha = 0
            }
        }
    }
    
    // MARK: - Firebase Listener
    func firebaseListener() {
        
        let reference = db.collection("Comments").document(post.documentID).collection("threads").order(by: "sentAt", descending: false)
        
        // Guckt ob sich was verändert
        listener = reference.addSnapshotListener { querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return      // Wenn squerySnapshot nicht snapshot ist
            }
            
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
        
        
        guard let id = docData["id"] as? Int,
            let body = docData["body"] as? String,
            let sentAtTimestamp = docData["sentAt"] as? Timestamp,
            let userUID = docData["userID"] as? String
            else {
                return    // Falls er das nicht zuordnen kann
        }
        if let userID = Auth.auth().currentUser?.uid {
            if userUID == userID {
                sender = true   // Die Nachricht stammt von ihm
            }
        }
        
        let sentDate:Date = sentAtTimestamp.dateValue()
        
        postHelper.getChatUser(uid: userUID, sender: sender, user: { (user) in
            
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
    
        let data : [String: Any] = ["body": bodyString, "id": message.id, "sentAt": Timestamp(date: Date()), "userID": currentUserUid]
        
        if let currentUser = currentUser { 
            let notificationRef = db.collection("Users").document(post.originalPosterUID).collection("notifications").document()
            let notificationData: [String: Any] = ["type": "comment", "comment": bodyString, "name": currentUser.displayName, "postID": self.post.documentID]
            
            notificationRef.setData(notificationData) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Successfully set notification")
                }
            }
        }
        
        reference.addDocument(data: data) { err in
            if let error = err {
                print("Error sending message: \(error.localizedDescription)")
                return
            }
        }
    }
    
    // MARK: - MSGMessengerStuff
    
//    override var style: MSGMessengerStyle {
//        let style = MessengerKit.Styles.iMessage
//        return style
//    }
    
    override func inputViewPrimaryActionTriggered(inputView: MSGInputView) {    // If somebody presses send
        
        
        let body: MSGMessageBody =  (inputView.message.containsOnlyEmoji && inputView.message.count < 5) ? .emoji(inputView.message) : .text(inputView.message)
        
        // inputView.message ist die Nachricht
        if let user = currentUser {
            if allowedToComment {
                let message = MSGMessage(id: id+1, body: body, user: user, sentAt: Date())
                
                if currentUserUid != "" {   // if you are a guest (not logged in)
                    saveInFirebase(bodyString: inputView.message, message: message)
                }
            } else {
                print("nothing happens cause blocked")
            }
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

