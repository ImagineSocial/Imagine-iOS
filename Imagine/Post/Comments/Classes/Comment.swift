//
//  Comment.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.07.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

protocol CommentDelegate {
    func childrenLoaded()
}

/*
 How does the commentSection works with indented Comments WHEN POSTING:
 1. answerButtonTapped() is called in the CommentCell
 2. CommentCellDelegate Function answerCommentTapped(comment: Comment) is called to move the selected Comment to the CommentTableView
 3. There, with the CommentTableViewDelegate, the function answerCommentTapped(comment: Comment) moves the chosen Comment to the selected ViewController (f.e. PostViewController)
 4. From there, the CommentAnswerView,.addReceiptField() gets called, so that the selected Comment ist shown above the CommentAnswerView
 //WITHOUT intedenenenenenion starts here
 5. If send is tapped in the CommentAnswerView, the CommentTableViewDelegate function .sendButtonTapped() gets called and sends the new Comment, along with the optional "answerToComment" to the selected ViewController
 6. There, the CommentTableView function saveCommentInDatabase() is called, the reference is different (.collection(children()) if a "answerToComment" is chosen
 7. After it is saved, the Comment will be shown in the TableView via addCommentToTableView()
 8. doneSaving() is called from the CommentTableViewDelegate
 9. Hui
 
 FETCHING:
 1. getComments in CommentTableView
 2. Comment.getChildren() gets called in every fetched Comment
 3. If there are any, they get fetched and call the CommentDelegate function childrenLoaded()
 4. The CommentTableView gets reloaded
 */

class Comment {
    
    init(commentSection: CommentSection, sectionItemID: String, commentID: String) {
        self.section = commentSection
        self.sectionItemID = sectionItemID
        self.commentID = commentID
    }
    var section: CommentSection
    var title = ""
    var text = ""
    var createTimeString = ""
    var createTime = Date()
    var author = ""
    var sectionItemID: String
    var sectionItemLanguage = Language.de
    var isTopicPost = false
    var upvotes: Votes?
    var likes = 0
    var user: User?
    var commentID: String
    var isIndented = false
    var delegate: CommentDelegate?
    
    var children: [Comment]? {
        didSet {
            print("Got Children!")
            delegate?.childrenLoaded()
        }
    }
    var parent: Comment?
    
    private let db = FirestoreRequest.shared.db
    
    func getChildren() {

        let ref: CollectionReference!
        
        switch section {
        case .post:
            ref =  db.collection("Comments").document(sectionItemID).collection("threads").document(commentID).collection("children")
        case .proposal:
            ref = db.collection("Comments").document("proposals").collection("comments").document(sectionItemID).collection("threads").document(commentID).collection("children")
        case .argument:
            ref = db.collection("Comments").document("arguments").collection("comments").document(sectionItemID).collection("threads").document(commentID).collection("children")
        case .counterArgument:
            ref = db.collection("Comments").document("arguments").collection("comments").document(sectionItemID).collection("threads").document(commentID).collection("children")
        case .source:
            ref = db.collection("Comments").document("sources").collection("comments").document(sectionItemID).collection("threads").document(commentID).collection("children")
        }
        

        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    var children = [Comment]()
                    
                    for document in snap.documents {
                        let data = document.data()

                        self.initializeCommentFromData(sectionItemID: self.sectionItemID, commentID: document.documentID, data: data) { (comment) in
                            comment.isIndented = true
                            comment.parent = self
                            children.append(comment)
                            
                            if children.count == snap.documents.count {
                                self.children = children
                            }
                        }
                    }
                }
            }
        }
    }
    
    func initializeCommentFromData(sectionItemID: String, commentID: String, data: [String:Any], done: @escaping (Comment) -> Void) {
        
        guard let body = data["body"] as? String,
            let sentAtTimestamp = data["sentAt"] as? Timestamp,
            let userUID = data["userID"] as? String
            else {
                return
        }
        
        let user = User(userID: userUID)
        user.loadUser() { user in
            let comment = Comment(commentSection: self.section, sectionItemID: sectionItemID, commentID: commentID)
            if let likes = data["likes"] as? [String] {
                comment.likes = likes.count
            }
            comment.createTime = sentAtTimestamp.dateValue()
            comment.user = user
            comment.text = body
            comment.commentID = commentID
            comment.sectionItemID = sectionItemID
            
            done(comment)
        }
    }
}
