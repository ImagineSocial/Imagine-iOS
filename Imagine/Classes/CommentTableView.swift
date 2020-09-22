//
//  CommentTableView.swift
//  Imagine
//
//  Created by Malte Schoppe on 20.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

enum CommentSection {
    case post
    case argument
    case source
    case proposal
    case counterArgument
    case addOn
}

protocol CommentTableViewDelegate {
    func doneSaving() //// Tells the parent that the input text was successfully saved
    func notLoggedIn()
    func notAllowedToComment()
    func commentGotReported(comment: Comment)
    func commentGotDeleteRequest(comment: Comment, answerToComment: Comment?)
    func toUserTapped(user: User)
    func recipientChanged(isActive: Bool, userUID: String)
    func answerCommentTapped(comment: Comment)
}

class CommentTableView: UITableView {

    var comments = [Comment]()
    var allowedToComment = true
    var currentUser: User?
    var section: CommentSection?
    
    let commentIdentifier = "CommentCell"
    let answerCellIdentifier = "AddOnQAndAAnswerCell"
    
    let db = Firestore.firestore()
    
    var commentDelegate: CommentTableViewDelegate?
    
    var headerView: CommentTableViewHeader?
    
    var post: Post? {
        didSet {
            self.checkIfTheCurrentUserIsBlocked(post: post!)
            getcomments()
        }
    }
    var argument: Argument? {
        didSet {
            getcomments()
        }
    }
    var source: Source? {
        didSet {
            getcomments()
        }
    }
    var proposal: Campaign? {
        didSet {
            getcomments()
        }
    }
    var counterArgument: Argument? {
        didSet {
            getcomments()
        }
    }
    
    // I'm to stupid to get the normal initializers to work with custom variables
    func initializeCommentTableView(section: CommentSection, notificationRecipients: [String]?) {
        self.section = section
        setCurrentUser()
        
        delegate = self
        dataSource = self
        
        register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: commentIdentifier)
        estimatedRowHeight = 100
        rowHeight = UITableView.automaticDimension
        separatorStyle = .none
        
        if section != .addOn {
            self.headerView = CommentTableViewHeader(frame: CGRect(x: 0, y: 0, width: 276, height: 30))
            self.headerView!.delegate = self
            if let user = Auth.auth().currentUser, let recipients = notificationRecipients {
                for recipient in recipients {
                    if user.uid == recipient {
                        self.headerView!.showNotificationButton()
                    }
                }
            }
            self.tableHeaderView = self.headerView
        } else {
            register(UINib(nibName: "AddOnQAndAAnswerCell", bundle: nil), forCellReuseIdentifier: answerCellIdentifier)
        }
    }
    
    func getcomments() {
        
        guard let section = section,
            let refAndID = getCommentRefAndID()
            else { return }
        
        refAndID.commentReference.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        
                        let docData = document.data()
                        
                        let comment = Comment(commentSection: section, sectionItemID: refAndID.sectionItemID, commentID: document.documentID)
                        comment.initializeCommentFromData(sectionItemID: refAndID.sectionItemID, commentID: document.documentID, data: docData) { (comment) in
                            
                            comment.getChildren()
                            comment.delegate = self
                            self.addCommentToTableView(comment: comment, answerToComment: nil)
                        }
                    }
                }
            }
        }
    }
    
    func getCommentRefAndID() -> (commentReference: Query, sectionItemID: String)? {
        
        guard let section = section else { return nil}
        
        var ref: Query!
        var sectionItemID: String!
        
        switch section {
        case .post:
            ref = db.collection("Comments").document(post!.documentID).collection("threads").order(by: "sentAt", descending: false)
            sectionItemID = post!.documentID
        case .argument:
            ref = db.collection("Comments").document("arguments").collection("comments").document(argument!.documentID).collection("threads").order(by: "sentAt", descending: false)
            sectionItemID = argument!.documentID
        case .source:
            ref = db.collection("Comments").document("sources").collection("comments").document(source!.documentID).collection("threads").order(by: "sentAt", descending: false)
            sectionItemID = source!.documentID
        case .proposal:
            ref = db.collection("Comments").document("proposals").collection("comments").document(proposal!.documentID).collection("threads").order(by: "sentAt", descending: false)
            sectionItemID = proposal!.documentID
        case .counterArgument:
            ref = db.collection("Comments").document("arguments").collection("comments").document(counterArgument!.documentID).collection("threads").order(by: "sentAt", descending: false)
            sectionItemID = counterArgument!.documentID
        case .addOn:
            ref = db.collection("Comments").document(post!.documentID).collection("threads").order(by: "sentAt", descending: false)
            sectionItemID = post!.documentID
        }
        
        return (ref, sectionItemID)
    }
    
    func addCommentToTableView(comment: Comment, answerToComment: Comment?) {
        if let answerToComment = answerToComment {
            if let rightComment = self.comments.first(where: {$0.commentID == answerToComment.commentID}) {
                
                comment.isIndented = true
                
                if var children = answerToComment.children {
                    children.append(comment)
                    answerToComment.children = children
                } else {
                    let children = [comment]
                    rightComment.children = children
                }
                self.reloadData()
            } else {
               // item could not be found
                self.comments.append(comment)
                self.comments.sort(by: { $0.createTime.compare($1.createTime) == .orderedAscending })
                self.reloadData()
            }
        } else {
            self.comments.append(comment)
            self.comments.sort(by: { $0.createTime.compare($1.createTime) == .orderedAscending })
            self.reloadData()
        }
    }
    
    func deleteCommentFromTableView(comment: Comment, answerToComment: Comment?) {
        if let answerToComment = answerToComment {
            if let section = comments.firstIndex(where: { (comm) -> Bool in
                comm.commentID == answerToComment.commentID
            }) {
                let sectionComment = comments[section]

                if let children = sectionComment.children {
                    if let row = children.firstIndex(where: { (comm) -> Bool in
                        comm.commentID == comment.commentID
                    }) {

                        let indexPath = IndexPath(row: row, section: section)
                        self.updateTableView(indexPath: indexPath)
                    }
                }
            }
        } else {
            if let index = comments.firstIndex(where: { (comm) -> Bool in
                comm.commentID == comment.commentID
            }) {
                let indexPath = IndexPath(row: 0, section: index)

                self.updateTableView(indexPath: indexPath)
            }
        }
        
        
        
    }
    
    /*
     self.beginUpdates()
     let indexPath = IndexPath(row: index, section: 0)
     self.comments.remove(at: index)
     self.deleteRows(at: [indexPath], with: .automatic)
     self.endUpdates()
     */
    
    func updateTableView(indexPath: IndexPath) {
        self.beginUpdates()
        if indexPath.row == 0 { // Top Level got deleted
            self.comments.remove(at: indexPath.section)
            let indexSet = IndexSet(arrayLiteral: indexPath.section)
            self.deleteSections(indexSet, with: .automatic)
        } else {
            let comment = self.comments[indexPath.section]
            
            if var children = comment.children {
                children.remove(at: indexPath.row)
                comment.children = children
                
                self.deleteRows(at: [indexPath], with: .automatic)
            }
        }
        self.endUpdates()
    }
    
    func checkIfTheCurrentUserIsBlocked(post: Post) {
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
            }
        }
    }
    
    func setCurrentUser() {
        if let user = Auth.auth().currentUser {
            self.getUser(userUID: user.uid) { (currentUser) in
                self.currentUser = currentUser
            }
        }
    }
    
    func getUser(userUID: String, returnUser: @escaping (User?) -> Void) {
        let ref = db.collection("Users").document(userUID)
        
        if userUID == "anonym" {
            returnUser(nil)
        } else {
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let document = snap {
                        if let data = document.data() {
                            
                            let user = User()
                            user.displayName = data["name"] as? String ?? ""
                            user.imageURL = data["profilePictureURL"] as? String ?? ""
                            user.userUID = userUID
                            
                            returnUser(user)
                        }
                    }
                }
            }
        }
    }
    
    func saveCommentInDatabase(bodyString: String, isAnonymous: Bool, answerToComment: Comment?) {
        
        guard let section = section else { return }
        
        var sectionItemID: String!
        
        if let user = Auth.auth().currentUser {
            
            if allowedToComment {
                guard let currentUser = currentUser else {
                    return
                }
                
                var ref: DocumentReference!
                
                var displayName = ""
                var userID = ""
                
                if isAnonymous {
                    displayName = "anonym"
                    userID = "anonym"
                } else {
                    displayName = currentUser.displayName
                    userID = user.uid
                }
                
                switch section {
                case .post:
                    if let post = post {
                        if let comment = answerToComment {
                            ref = db.collection("Comments").document(post.documentID).collection("threads").document(comment.commentID).collection("children").document()
                        } else {
                            ref = db.collection("Comments").document(post.documentID).collection("threads").document()
                        }
                        
                        if post.originalPosterUID != "" {
                            self.getNotificationRecipients(post: post, bodyString: bodyString, displayName: displayName, commenterUID: userID)
                        }
                        sectionItemID = post.documentID
                    }
                case .argument:
                    if let comment = answerToComment {
                        ref = db.collection("Comments").document("arguments").collection("comments").document(argument!.documentID).collection("threads").document(comment.commentID).collection("children").document()
                    } else {
                        ref = db.collection("Comments").document("arguments").collection("comments").document(argument!.documentID).collection("threads").document()
                    }
                    sectionItemID = argument!.documentID
                case .source:
                    if let comment = answerToComment {
                        ref = db.collection("Comments").document("sources").collection("comments").document(source!.documentID).collection("threads").document(comment.commentID).collection("children").document()
                    } else {
                        ref = db.collection("Comments").document("sources").collection("comments").document(source!.documentID).collection("threads").document()
                    }
                    sectionItemID = source!.documentID
                case .proposal:
                    if let comment = answerToComment {
                        ref = db.collection("Comments").document("proposals").collection("comments").document(proposal!.documentID).collection("threads").document(comment.commentID).collection("children").document()
                    } else {
                        ref = db.collection("Comments").document("proposals").collection("comments").document(proposal!.documentID).collection("threads").document()
                    }
                    sectionItemID = proposal!.documentID
                case .counterArgument:
                    if let comment = answerToComment {
                        ref = db.collection("Comments").document("arguments").collection("comments").document(counterArgument!.documentID).collection("threads").document(comment.commentID).collection("children").document()
                    } else {
                        ref = db.collection("Comments").document("arguments").collection("comments").document(counterArgument!.documentID).collection("threads").document()
                    }
                    sectionItemID = counterArgument!.documentID
                case .addOn:
                    if let post = post {
                        if let comment = answerToComment {
                            ref = db.collection("Comments").document(post.documentID).collection("threads").document(comment.commentID).collection("children").document()
                        } else {
                            ref = db.collection("Comments").document(post.documentID).collection("threads").document()
                        }
                        
                        if post.originalPosterUID != "" {
                            self.getNotificationRecipients(post: post, bodyString: bodyString, displayName: displayName, commenterUID: userID)
                        }
                        sectionItemID = post.documentID
                    }
                }
                
                let data : [String: Any] = ["body": bodyString, "id": 0, "sentAt": Timestamp(date: Date()), "userID": userID]
                 
                
                
                ref.setData(data) { (err) in
                    if let error = err {
                        print("Error sending message: \(error.localizedDescription)")
                        return
                    } else {
                        
                        let comment = Comment(commentSection: section, sectionItemID: sectionItemID, commentID: ref.documentID)
                        comment.createTime = Date()
                        
                        if isAnonymous {
                            self.saveAnonymousCommentReference(documentID: ref.documentID, userUID: user.uid, section: section)
                        } else {
                            comment.user = currentUser  // No User if its anonymous
                        }
                        comment.text = bodyString
                        
                        self.addCommentToTableView(comment: comment, answerToComment: answerToComment)
                        
                        self.commentDelegate?.doneSaving()
                    }
                }
                
            } else {
                self.commentDelegate?.notAllowedToComment()
            }
        } else {
            self.commentDelegate?.notLoggedIn()
        }
    }
    
    func saveAnonymousCommentReference(documentID: String, userUID: String, section: CommentSection) {
        
        var sectionString = ""
        var documentID = ""
        
        switch section {
        case .argument:
            sectionString = "argument"
            documentID = argument!.documentID
        case .source:
            sectionString = "source"
            documentID = source!.documentID
        case .post:
            sectionString = "post"
            documentID = post!.documentID
        case .proposal:
            sectionString = "proposal"
            documentID = proposal!.documentID
        case .counterArgument:
            sectionString = "counterArgument"
            documentID = counterArgument!.documentID
        case .addOn:
            sectionString = "post"
            documentID = post!.documentID
        }
        
        let data: [String: Any] = ["createTime": Timestamp(date: Date()), "originalPoster": userUID, "section": sectionString, "documentID": documentID]
        
        let ref = db.collection("AnonymousPosts")
        
            ref.addDocument(data: data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            }
        }
        
    }
    
    func getNotificationRecipients(post: Post, bodyString: String, displayName: String, commenterUID: String) {
        let ref: DocumentReference!
        
        if post.isTopicPost {
            ref = db.collection("TopicPosts").document(post.documentID)
        } else {
            ref = db.collection("Posts").document(post.documentID)
        }
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let recipients = data["notificationRecipients"] as? [String] {
                            
                            self.checkIfUserNeedsToBeAdded(post: post, recipients: recipients, commenterUID: commenterUID)
                            
                            for recipient in recipients {
                                if recipient == commenterUID {
                                    continue // No notification for your own comment
                                } else {
                                    if recipient == post.originalPosterUID {
                                        self.setNotification(post: post, userID: recipient, bodyString: bodyString, displayName: displayName, forOP: true)
                                    } else {
                                        self.setNotification(post: post, userID: recipient, bodyString: bodyString, displayName: displayName, forOP: false)
                                    }
                                }
                            }
                        } else {
                            if commenterUID != "anonym" {
                                self.addUserAsNotificationRecipient(post: post, userUID: commenterUID)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkIfUserNeedsToBeAdded(post: Post, recipients: [String], commenterUID: String) {
        if commenterUID != "anonym" {
            
            for recipient in recipients {
                if commenterUID == recipient {  // If User is already notificationRecipient
                    return
                }
            }
            self.addUserAsNotificationRecipient(post: post, userUID: commenterUID)
        }
    }
    
    func addUserAsNotificationRecipient(post: Post, userUID: String) {
        
        let ref = db.collection("Posts").document(post.documentID)
        ref.updateData([
            "notificationRecipients" : FieldValue.arrayUnion([userUID])
        ])
        
        self.commentDelegate?.recipientChanged(isActive: true, userUID: userUID)
        
        if let header = self.tableHeaderView as? CommentTableViewHeader {
            header.showNotificationButton()
        }
    }
    
    
    func removeUserAsNotificationRecipient(post: Post, userUID: String) {
        let ref = db.collection("Posts").document(post.documentID)
        ref.updateData([
            "notificationRecipients" : FieldValue.arrayRemove([userUID])
        ])
        
        self.commentDelegate?.recipientChanged(isActive: false, userUID: userUID)
        
    }
    
    func setNotification(post: Post, userID: String, bodyString: String, displayName: String, forOP: Bool) {
        
        let notificationRef = db.collection("Users").document(userID).collection("notifications").document()
        
        let notificationData: [String: Any] = ["type": "comment", "comment": bodyString, "name": displayName, "postID": post.documentID, "isTopicPost": post.isTopicPost, "forOP": forOP]   //"forOP" changes the message in the notification: "You got a comment: " vs "X-Post got a comment"
        
        notificationRef.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
    
}

extension CommentTableView: UITableViewDataSource, UITableViewDelegate {
    //MARK:-TableViewDelegate/DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let comment = comments[section]
        if let children = comment.children {
            return children.count+1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var comment = comments[indexPath.section]
        if let children = comment.children {
            if indexPath.row != 0 { //Not Top level Comment
                comment = children[indexPath.row-1]
            }
        }
        
        if let cell = dequeueReusableCell(withIdentifier: commentIdentifier, for: indexPath) as? CommentCell {
            
            cell.delegate = self
            cell.comment = comment
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var comment = comments[indexPath.section]
        if let children = comment.children {
            if indexPath.row != 0 { //Not Top level Comment
                comment = children[indexPath.row-1]
            }
        }
        
        let editAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("comment_report_label", comment: "report")) { (rowAction, indexPath) in
            
            self.commentDelegate?.commentGotReported(comment: comment)
        }
        editAction.backgroundColor = .imagineColor
        
        if let user = Auth.auth().currentUser {
            if let commentAuthor = comment.user {
                if user.uid == commentAuthor.userUID {
                    let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("delete", comment: "delete")) { (rowAction, indexPath) in
                        
                        if comment.isIndented {
                            let answerToComment = self.comments[indexPath.section]
                            self.commentDelegate?.commentGotDeleteRequest(comment: comment, answerToComment: answerToComment)
                        } else {
                            self.commentDelegate?.commentGotDeleteRequest(comment: comment, answerToComment: nil)
                        }
                    }
                    
                    return [deleteAction, editAction]
                } else {
                    return [editAction]
                }
            } else {
                return [editAction]
            }
        } else {
            
            return [editAction]
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    //MARK:- TableView Height
    //Turn height of TableView to the height of all comments Combined
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

extension CommentTableView: CommentTableViewHeaderDelegate, CommentCellDelegate {
   
    func answerCommentTapped(comment: Comment) {
        commentDelegate?.answerCommentTapped(comment: comment)
    }
    
    
    func userTapped(user: User) {
        commentDelegate?.toUserTapped(user: user)
    }
    
    
    func switchChanged(isOn: Bool) {
        if let user = Auth.auth().currentUser, let post = post {
            if isOn {
                self.addUserAsNotificationRecipient(post: post, userUID: user.uid)
            } else {
                self.removeUserAsNotificationRecipient(post: post, userUID: user.uid)
            }
        }
    }
}

extension CommentTableView: CommentDelegate {
    func childrenLoaded() {
        self.reloadData()
    }
}

protocol CommentTableViewHeaderDelegate {
    func switchChanged(isOn: Bool)
}

class CommentTableViewHeader: UIView {
    
    var delegate: CommentTableViewHeaderDelegate?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setLayouts()
    }
    
    func setLayouts() {
        addSubview(label)
        label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2).isActive = true
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15).isActive = true

        addSubview(separator)
        separator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 1).isActive = true
        separator.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15).isActive = true
        separator.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        addSubview(notificationSwitch)
        notificationSwitch.widthAnchor.constraint(equalToConstant: 25).isActive = true
        notificationSwitch.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -30).isActive = true
        notificationSwitch.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: 3).isActive = true
        
        addSubview(notificationLabel)
        notificationLabel.trailingAnchor.constraint(equalTo: notificationSwitch.leadingAnchor, constant: -5).isActive = true
        notificationLabel.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: 0).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showNotificationButton() {
        UIView.animate(withDuration: 0.3, animations: {
            self.notificationLabel.alpha = 1
            self.notificationSwitch.alpha = 1
            self.notificationSwitch.isEnabled = true
        }) { (_) in
            
        }
    }
    
    @objc func switchChanged() {
        delegate?.switchChanged(isOn: self.notificationSwitch.isOn)
    }
    
    //MARK:UI
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 15)
        label.textAlignment = .left
        label.text = NSLocalizedString("comment_header_label", comment: "comments:")
        
        return label
    }()
    
    let separator: UIView = {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            separator.backgroundColor = .separator
        } else {
            separator.backgroundColor = .lightGray
        }
        
        return separator
    }()
    
    lazy var notificationSwitch: UISwitch = {
       let notSwitch = UISwitch()
        notSwitch.translatesAutoresizingMaskIntoConstraints = false
        notSwitch.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        notSwitch.isOn = true
        notSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        notSwitch.alpha = 0
        notSwitch.isEnabled = false
        
        return notSwitch
    }()
    
    let notificationLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        if #available(iOS 13.0, *) {
            label.textColor = .secondaryLabel
        } else {
            label.textColor = .darkGray
        }
        label.textAlignment = .left
        label.text = NSLocalizedString("comment_notifications_label", comment: "notifications:")
        label.alpha = 0

        return label
    }()
}
