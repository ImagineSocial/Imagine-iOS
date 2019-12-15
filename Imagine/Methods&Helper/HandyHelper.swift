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
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let stringDate = formatter.string(from: date)
        
        return stringDate
    }
    
    func getUser(userUID: String) -> User {
        
        // User Daten raussuchen
        let userRef = db.collection("Users").document(userUID)
        
        let user = User()
        
        userRef.getDocument(completion: { (document, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else if let document = document {
                if let docData = document.data() {
                    
                    user.name = docData["name"] as? String ?? ""
                    user.surname = docData["surname"] as? String ?? ""
                    user.imageURL = docData["profilePictureURL"] as? String ?? ""
                    user.userUID = userUID
                    
                }
            }
        })
        
        return user
    }
    
    func getUsers(userList: [String], completion: @escaping ([User]) -> Void) {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        var users = [User]()
        
        for user in userList {
            // User Daten raussuchen
            let userRef = db.collection("Users").document(user)
            
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        let user = User()
                        
                        user.name = docData["name"] as? String ?? ""
                        user.surname = docData["surname"] as? String ?? ""
                        user.imageURL = docData["profilePictureURL"] as? String ?? ""
                        user.userUID = document.documentID
                        
                        users.append(user)
                        
                        completion(users)
                    }
                }
                
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "")")
                }
            })
        }
    }
    
    func setLabelHeight(titleCount: Int) -> CGFloat {
        // Stellt die Höhe für das TitleLabel ein bei cellForRow und HeightForRow
        var labelHeight : CGFloat = 20  // One line
        
        if titleCount <= 40 {           // Two Lines
            labelHeight = 40
        } else if titleCount <= 80 {    // Three Lines
            labelHeight = 50
        } else if titleCount <= 120 {   // Four Lines
            labelHeight = 90
        } else if titleCount <= 160 {   //  5 Lines
            labelHeight = 115
        } else if titleCount <= 200 {   // 6 Lines
            labelHeight = 145
        }
        
        return labelHeight
    }
    
    func setReportView(post: Post) -> (heightConstant:CGFloat, buttonHidden: Bool, labelText: String, backgroundColor: UIColor) {
        
        var reportViewHeightConstraint:CGFloat = 24
        var reportViewButtonInTopBoolean = false
        var reportViewLabelText = ""
        var reportViewBackgroundColor = UIColor.white
        
        switch post.report {
        case .normal:
            reportViewHeightConstraint = 0
            reportViewButtonInTopBoolean = true
        case .spoiler:
            reportViewLabelText = "Spoiler" // I think always the same excet arabic or whatever
            reportViewBackgroundColor = .red
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
        let db = Firestore.firestore().collection("Posts").document(post.documentID)
        var keyForFirestore = ""
        var valueForFirestore = 0
        
        switch button {
        case .thanks:
            valueForFirestore = post.votes.thanks+1
            keyForFirestore = "thanksCount"
        case .wow:
            valueForFirestore = post.votes.wow+1
            keyForFirestore = "wowCount"
        case .ha:
            valueForFirestore = post.votes.ha+1
            keyForFirestore = "haCount"
        case .nice:
            valueForFirestore = post.votes.nice+1
            keyForFirestore = "niceCount"
        }
        
        if keyForFirestore != "" {
            db.updateData([keyForFirestore:valueForFirestore])
        } else {
            print("Could not update")
        }
        
        if !post.anonym {
            notifyUserForUpvote(button: button, post: post)
        }
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
            let data = ["type": "upvote", "button": button, "postID": post.documentID, "title": post.title]
            
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
        default:
            print("Something Wrong")
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
                    if snap!.documents.count != 0 {
                        // Already saved
                        saved = true
                    }
                    alreadySaved(saved)
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
                
                for document in snap!.documents {
                    document.reference.delete()
                }
            }
        }
    }
    
    
}
