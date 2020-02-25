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
}

protocol CommentTableViewDelegate {
    func doneSaving()
    func notLoggedIn()
    func notAllowedToComment()
    func commentGotReported(comment: Comment)
}

class CommentTableView: UITableView, UITableViewDataSource, UITableViewDelegate {

    var comments = [Comment]()
    var allowedToComment = true
    var currentUser: User?
    var section: CommentSection?
    
    let commentIdentifier = "CommentCell"
    
    let db = Firestore.firestore()
    
    var commentDelegate: CommentTableViewDelegate?
    
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
    func initializeCommentTableView(section: CommentSection) {
        self.section = section
        setCurrentUser()
        
        delegate = self
        dataSource = self
        
        register(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: commentIdentifier)
        estimatedRowHeight = 100
        rowHeight = UITableView.automaticDimension
        separatorStyle = .none
        
        self.tableHeaderView = self.headerView
    }
    
    func getcomments() {
        var ref: Query?
        
        guard let section = section else { return }
        
        switch section {
        case .post:
            ref = db.collection("Comments").document(post!.documentID).collection("threads").order(by: "sentAt", descending: false)
        case .argument:
            ref = db.collection("Comments").document("arguments").collection("comments").document(argument!.documentID).collection("threads").order(by: "sentAt", descending: false)
        case .source:
            ref = db.collection("Comments").document("sources").collection("comments").document(source!.documentID).collection("threads").order(by: "sentAt", descending: false)
        case .proposal:
            ref = db.collection("Comments").document("proposals").collection("comments").document(proposal!.documentID).collection("threads").order(by: "sentAt", descending: false)
        case .counterArgument:
            ref = db.collection("Comments").document("arguments").collection("comments").document(counterArgument!.documentID).collection("threads").order(by: "sentAt", descending: false)
            
        }
        
        if let reference = ref {
            reference.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        for document in snap.documents {
                            
                            let docData = document.data()
                            
                            guard let body = docData["body"] as? String,
                                let sentAtTimestamp = docData["sentAt"] as? Timestamp,
                                let userUID = docData["userID"] as? String
                                else {
                                    continue    // Falls er das nicht zuordnen kann
                            }
                            
                            self.getUser(userUID: userUID) { (user) in
                                let comment = Comment()
                                comment.createTime = sentAtTimestamp.dateValue()
                                comment.user = user
                                comment.text = body
                                comment.documentID = document.documentID
                                
                                self.addCommentToTableView(comment: comment)
                            }
                        }
                    }
                }
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
                            
                            returnUser(user)
                        }
                    }
                }
            }
        }
    }
    
    func addCommentToTableView(comment: Comment) {
        self.comments.append(comment)
        self.comments.sort(by: { $0.createTime.compare($1.createTime) == .orderedAscending })
        self.reloadData()
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
    
    func saveCommentInDatabase(bodyString: String, isAnonymous: Bool) {
        
        guard let section = section else { return }
        
        if let user = Auth.auth().currentUser {
            
            if allowedToComment {
                guard let currentUser = currentUser else {
                    return
                }
                
                var ref: DocumentReference?
                
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
                    ref = db.collection("Comments").document(post!.documentID).collection("threads").document()
                    
                    if user.uid != post!.originalPosterUID && post!.originalPosterUID != "" {
                        self.setNotification(post: post!, bodyString: bodyString, displayName: displayName)
                    } else {
                        print("No notification if you comment your own post")
                    }
                    
                case .argument:
                    ref = db.collection("Comments").document("arguments").collection("comments").document(argument!.documentID).collection("threads").document()
                case .source:
                    ref = db.collection("Comments").document("sources").collection("comments").document(source!.documentID).collection("threads").document()
                case .proposal:
                    ref = db.collection("Comments").document("proposals").collection("comments").document(proposal!.documentID).collection("threads").document()
                case .counterArgument:
                    ref = db.collection("Comments").document("arguments").collection("comments").document(counterArgument!.documentID).collection("threads").document()
                }
                
                let data : [String: Any] = ["body": bodyString, "id": 0, "sentAt": Timestamp(date: Date()), "userID": userID]
                
                if let reference = ref {
                    
                    reference.setData(data) { (err) in
                        if let error = err {
                            print("Error sending message: \(error.localizedDescription)")
                            return
                        } else {
                            
                            let comment = Comment()
                            comment.createTime = Date()
                            
                            if isAnonymous {
                                self.saveAnonymousCommentReference(documentID: reference.documentID, userUID: user.uid, section: section)
                            } else {
                                comment.user = currentUser  // No User if its anonymous
                            }
                            comment.text = bodyString
                            
                            self.addCommentToTableView(comment: comment)
                            
                            self.commentDelegate?.doneSaving() //// Tells the parent that the input text was successfully saved
                        }
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
        }
        
        let data: [String: Any] = ["createTime": Timestamp(date: Date()), "originalPoster": userUID, "section": sectionString, "documentID": documentID]
        
        let ref = db.collection("AnonymousPosts")
        
            ref.addDocument(data: data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            }
        }
        
    }
    
    func setNotification(post: Post, bodyString: String, displayName: String) {
        let notificationRef = db.collection("Users").document(post.originalPosterUID).collection("notifications").document()
        let notificationData: [String: Any] = ["type": "comment", "comment": bodyString, "name": displayName, "postID": post.documentID]
        
        notificationRef.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
    
    //MARK:-TableViewDelegate/DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let comment = comments[indexPath.row]
        
        if let cell = dequeueReusableCell(withIdentifier: commentIdentifier, for: indexPath) as? CommentCell {
            
            cell.comment = comment
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let editAction = UITableViewRowAction(style: .normal, title: "Melden") { (rowAction, indexPath) in
            let comment = self.comments[indexPath.row]
            
            self.commentDelegate?.commentGotReported(comment: comment)
        }
        editAction.backgroundColor = .imagineColor
        
        return [editAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    //MARK: HeaderView
    
    let headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 276, height: 30))
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 15)
        label.textAlignment = .left
        label.text = "Kommentare:"

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            separator.backgroundColor = .separator
        } else {
            separator.backgroundColor = .lightGray
        }

        view.addSubview(label)
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true

        view.addSubview(separator)
        separator.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 1).isActive = true
        separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        return view
    }()

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
