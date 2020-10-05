//
//  HandyHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import DateToolsSwift
import AVKit

enum VoteButton {
    case thanks
    case wow
    case ha
    case nice
}

enum NotificationType {
    case message
    case friend
    case comment
    case blogPost
    case upvote
}


class HandyHelper {
    
    let db = Firestore.firestore()
    
    func getDateAsTimestamp() -> Timestamp {
        let date = Date()
        let timestamp = Timestamp(date: date)

        return timestamp
    }
    
    func getStringDate(timestamp: Timestamp) -> String {
        // Timestamp umwandeln
        let formatter = DateFormatter()
        let date:Date = timestamp.dateValue()
        let language = LanguageSelection().getLanguage()
        if language == .german {
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
        } else {
            formatter.dateFormat = "MM/dd/yyyy HH:mm"
        }
        let stringDate = formatter.string(from: date)
        
        return stringDate
    }
    
    func getUserForNewBlogpostOnly(userUID: String) -> User {   // Only for Blogpost cause it gets the whole name, no matter if friend or not
        
        // User Daten raussuchen
        let userRef = db.collection("Users").document(userUID)
        
        let user = User()

        userRef.getDocument(completion: { (document, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else if let document = document {
                if let docData = document.data() {

                    let name = docData["name"] as? String ?? ""
                    let surname = docData["surname"] as? String ?? ""
                    user.imageURL = docData["profilePictureURL"] as? String ?? ""
                    user.userUID = userUID
                    user.displayName = "\(name) \(surname)"
                    
                    
                }
            }
        })

        return user
    }

    
    func setLabelHeight(titleCount: Int) -> CGFloat {
        var labelHeight : CGFloat = 15  // One line
        
        if titleCount <= 50 {           // Two Lines
            labelHeight = 40
        } else if titleCount <= 100 {    // Three Lines
            labelHeight = 50
        } else if titleCount <= 140 {   // Four Lines
            labelHeight = 90
        } else if titleCount <= 180 {   //  5 Lines
            labelHeight = 95
        } else if titleCount <= 200 {   // 6 Lines
            labelHeight = 115
        }
        
        return labelHeight
    }
    
    func setReportView(post: Post) -> (heightConstant:CGFloat, buttonHidden: Bool, labelText: String, backgroundColor: UIColor) {
        
        var reportViewHeightConstraint:CGFloat = 40
        var reportViewButtonInTopBoolean = false
        var reportViewLabelText = ""
        var reportViewBackgroundColor = UIColor.white
        
        let beautifulRed = UIColor(red: 0.75, green: 0.07, blue: 0.07, alpha: 1.00)
        
        switch post.report {
        case .normal:
            reportViewHeightConstraint = 0
            reportViewButtonInTopBoolean = true
        case .spoiler:
            reportViewLabelText = "Spoiler" // I think always the same excet arabic or whatever
            reportViewBackgroundColor = beautifulRed
        case .satire:
            reportViewLabelText = "Satire" // I think always the same excet arabic or whatever
            reportViewBackgroundColor = .orange
        case .misinformation:
            reportViewLabelText = NSLocalizedString("misinformation", comment: "misinformation")
            reportViewBackgroundColor = beautifulRed
        case .misleading:
            reportViewLabelText = NSLocalizedString("misleading", comment: "misleading")
            reportViewBackgroundColor = beautifulRed
        case .opinion:
            reportViewLabelText = NSLocalizedString("Opinion, not a fact", comment: "When it seems like the post is presenting a fact, but is just an opinion")
            reportViewBackgroundColor = UIColor(red:0.27, green:0.00, blue:0.01, alpha:1.0)
        case .sensationalism:
            reportViewLabelText = NSLocalizedString("Sensationalism", comment: "When the given facts are presented more important, than they are in reality")
            reportViewBackgroundColor = UIColor(red:0.36, green:0.00, blue:0.01, alpha:1.0)
        case .circlejerk:
            reportViewLabelText = "Circlejerk"
            reportViewBackgroundColor = UIColor(red:0.58, green:0.04, blue:0.05, alpha:1.0)
        case .pretentious:
            reportViewLabelText = NSLocalizedString("Pretentious", comment: "When the poster is just posting to sell themself")
            reportViewBackgroundColor = UIColor(red:0.83, green:0.05, blue:0.07, alpha:1.0)
        case .ignorant:
            reportViewLabelText = NSLocalizedString("Ignorant Thinking", comment: "If the poster is just looking at one side of the matter or problem")
            reportViewBackgroundColor = UIColor(red:1.00, green:0.46, blue:0.30, alpha:1.0)
        case .edited:
            reportViewLabelText = NSLocalizedString("Edited Content", comment: "If the person shares something that is corrected or changed with photoshop or whatever")
            reportViewBackgroundColor = UIColor(red:1.00, green:0.40, blue:0.36, alpha:1.0)
        }
        
        return (heightConstant: reportViewHeightConstraint, buttonHidden: reportViewButtonInTopBoolean, labelText: reportViewLabelText, backgroundColor: reportViewBackgroundColor)
    }
    
    
    func updatePost(button: VoteButton, post: Post) {
        var ref: DocumentReference?
        var collectionRef: CollectionReference!
        
        if post.isTopicPost {
            if post.language == .english {
                collectionRef = db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = db.collection("TopicPosts")
            }
            ref = collectionRef.document(post.documentID)
        } else {
            if post.language == .english {
                collectionRef = db.collection("Data").document("en").collection("posts")
            } else {
                collectionRef = db.collection("Posts")
            }
            ref = collectionRef.document(post.documentID)
        }
            
        var keyForFirestore: String?
        
        switch button {
        case .thanks:
            keyForFirestore = "thanksCount"
        case .wow:
            keyForFirestore = "wowCount"
        case .ha:
            keyForFirestore = "haCount"
        case .nice:
            keyForFirestore = "niceCount"
        }
        
        if let keyForFirestore = keyForFirestore, let ref = ref {
            ref.updateData([
                keyForFirestore :  FirebaseFirestore.FieldValue.increment(Int64(1))
            ])
        } else {
            print("Could not update")
        }
        
        if !post.anonym {
            notifyUserForUpvote(button: button, post: post)
        }
    }


    func getWidthAndHeightFromVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
       let size = track.naturalSize.applying(track.preferredTransform)
        
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    func notifyUserForUpvote(button: VoteButton, post: Post) {
        
        var buttonString: String?
        
        switch button {
        case .thanks:
            buttonString = "thanks"
        case .wow:
            buttonString = "wow"
        case .ha:
            buttonString = "ha"
        case .nice:
            buttonString = "nice"
        }
        
        if let button = buttonString {
            
            var data: [String: Any] = ["type": "upvote", "button": button, "postID": post.documentID, "title": post.title]
            
            if post.isTopicPost {
                data["isTopicPost"] = true
            }
            if post.language == .english {
                data["language"] = "en"
            }
            
            let ref = db.collection("Users").document(post.originalPosterUID).collection("notifications").document()
            
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("notification set")
                }
            }
        }
    }
    
    func setPostType(fetchedString: String) -> PostType? {
        let postType :PostType?
        
        switch fetchedString {
        case "picture":
            postType = .picture
        case "thought":
            postType = .thought
        case "link":
            postType = .link
        case "event":
            postType = .event
        case "repost":
            postType = .repost
        case "youTubeVideo":
            postType = .youTubeVideo
        case "translation":
            postType = .repost  // Has to be changed
        case "GIF":
            postType = .GIF
        case "multiPicture":
            postType = .multiPicture
        default:
            print("Something Wrong: Unknown type in SetPostType - HandyHelper")
            return PostType.picture
        }
        
        return postType
    }
    
    
    func setReportType(fetchedString: String) -> ReportType? {
        let report :ReportType?
        
        switch fetchedString {
        case "opinion":
            report = .opinion
            return report
        case "sensationalism":
            report = .sensationalism
            return report
        case "circlejerk":
            report = .circlejerk
            return report
        case "pretentious":
            report = .pretentious
            return report
        case "edited":
            report = .edited
            return report
        case "ignorant":
            report = .ignorant
            return report
        case "normal":
            report = .normal
            return report
        case "spoiler":
            report = .spoiler
            return report
        case "misleading":
            report = .misleading
            return report
        case "misinformation":
            report = .misinformation
            return report
        default:
            print("Hier stimmt was nicht")
            return ReportType.normal
        }
    }
    
    func checkIfAlreadySaved(post: Post, alreadySaved: @escaping(Bool) -> Void ) {
        var saved = false
        
        if let user = Auth.auth().currentUser {
            let savedRef = db.collection("Users").document(user.uid).collection("saved").whereField("documentID", isEqualTo: post.documentID)
            savedRef.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if snap.documents.count != 0 {
                            // Already saved
                            saved = true
                        }
                        alreadySaved(saved)
                    } else {
                        alreadySaved(saved)
                    }
                }
            }
        }
    }
    
    func getLocaleCurrencyString(number: Double) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        
        if let priceString = currencyFormatter.string(from: NSNumber(value: number)) {
            return priceString
        } else {
            return String(number)
        }
    }
    
    func saveFCMToken(token:String) {
        if let user = Auth.auth().currentUser {
            let userRef = db.collection("Users").document(user.uid)
            
            userRef.setData(["fcmToken":token], mergeFields: ["fcmToken"])
            
            UserDefaults.standard.setValue(token, forKey: "fcmToken")
        }
    }
    
    func deleteNotifications(type: NotificationType, id: String) {
        print("delete Notification")
        
        if let user = Auth.auth().currentUser {
            
            switch type {
            case .message:
                let notRef = db.collection("Users").document(user.uid).collection("notifications").whereField("chatID", isEqualTo: id)
                
                self.deleteInFirebase(ref: notRef)
            case .comment:
                let notRef = db.collection("Users").document(user.uid).collection("notifications").whereField("postID", isEqualTo: id)
                
                self.deleteInFirebase(ref: notRef)
            case .friend:
                let notRef = db.collection("Users").document(user.uid).collection("notifications").whereField("userID", isEqualTo: id)
                
                self.deleteInFirebase(ref: notRef)
            case .blogPost:
                let notRef = db.collection("Users").document(user.uid).collection("notifications").whereField("type", isEqualTo: "blogPost")
                
                self.deleteInFirebase(ref: notRef)
            case .upvote:
                let notRef = db.collection("Users").document(user.uid).collection("notifications").whereField("type", isEqualTo: "upvote").whereField("postID", isEqualTo: id)
                
                self.deleteInFirebase(ref: notRef)
                
            }
        }
    }
    
    func deleteInFirebase(ref: Query) {
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    for document in snap.documents {
                        document.reference.delete()
                    }
                }
            }
        }
    }
    
    func deleteCommentInFirebase(comment: Comment, answerToComment: Comment?) {
        
        let ref = getCommentRef(comment: comment, answerToComment: answerToComment)
        
        ref.delete { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            }
        }
    }
    
    func getCommentRef(comment: Comment, answerToComment: Comment?) -> DocumentReference {
        let ref: DocumentReference!
        
        switch comment.section {
        case .post:
            if let answerToComment = answerToComment {
                ref = db.collection("Comments").document(answerToComment.sectionItemID).collection("threads").document(answerToComment.commentID).collection("children").document(comment.commentID)
            } else {
                ref = db.collection("Comments").document(comment.sectionItemID).collection("threads").document(comment.commentID)
            }
        case .proposal:
            if let answerToComment = answerToComment {
                ref = db.collection("Comments").document("proposals").collection("comments").document(answerToComment.sectionItemID).collection("threads").document(answerToComment.commentID).collection("children").document(comment.commentID)
            } else {
                ref = db.collection("Comments").document("proposals").collection("comments").document(comment.sectionItemID).collection("threads").document(comment.commentID)
            }
        case .source:
            if let answerToComment = answerToComment {
                ref = db.collection("Comments").document("sources").collection("comments").document(answerToComment.sectionItemID).collection("threads").document(answerToComment.commentID).collection("children").document(comment.commentID)
            } else {
                ref = db.collection("Comments").document("sources").collection("comments").document(comment.sectionItemID).collection("threads").document(comment.commentID)
            }
        default:    //argument and counterargument
            if let answerToComment = answerToComment {
                ref = db.collection("Comments").document("arguments").collection("comments").document(answerToComment.sectionItemID).collection("threads").document(answerToComment.commentID).collection("children").document(comment.commentID)
            } else {
                ref = db.collection("Comments").document("arguments").collection("comments").document(comment.sectionItemID).collection("threads").document(comment.commentID)
            }
        }
        
        return ref
    }
    
    func setLikeOnComment(comment: Comment, answerToComment: Comment?) {
        if let user = Auth.auth().currentUser {
            let ref = getCommentRef(comment: comment, answerToComment: answerToComment)
            
            ref.updateData([
                "likes" : FieldValue.arrayUnion([user.uid])
            ])
        } else {
            return
        }
    }
    
}
