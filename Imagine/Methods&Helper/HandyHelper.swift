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
import DateToolsSwift

enum VoteButton {
    case thanks
    case wow
    case ha
    case nice
}

extension Date {
    
    func formatRelativeString() -> String {
        let dateFormatter = DateFormatter()
        
        let calendar = Calendar(identifier: .gregorian)
        dateFormatter.doesRelativeDateFormatting = true
        
        if calendar.isDateInToday(self) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else if calendar.isDateInYesterday(self){
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
        } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
            let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
            return dateFormatter.weekdaySymbols[weekday-1]
        } else {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .short
        }
        
        return dateFormatter.string(from: self)
    }
}

class HandyHelper {
    
    let db = Firestore.firestore()
    
    func getDateAsTimestamp() -> Timestamp {
                let date = Date()
        let timestamp = Timestamp(date: date)
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd MM yyyy HH:mm"
//        let stringDate = formatter.string(from: date)
//        if let result = formatter.date(from: stringDate) {
//            let dateTimestamp :Timestamp = Timestamp(date: result)  // Hat keine Nanoseconds
//            return dateTimestamp
//        }
        return timestamp
    }
    
    func getStringDate(timestamp: Timestamp) -> String {
        // Timestamp umwandeln
        let formatter = DateFormatter()
        let date:Date = timestamp.dateValue()
        formatter.dateFormat = "dd MM yyyy HH:mm"
        let stringDate = formatter.string(from: date)
        
        return stringDate
    }
    
    func getUser(userUID: String) -> User {
        
        // User Daten raussuchen
        let userRef = db.collection("Users").document(userUID)
        
        let user = User()
        
        userRef.getDocument(completion: { (document, err) in
            if let document = document {
                if let docData = document.data() {
                    
                    user.name = docData["name"] as? String ?? ""
                    user.surname = docData["surname"] as? String ?? ""
                    user.imageURL = docData["profilePictureURL"] as? String ?? ""
                    user.userUID = userUID
                    
                }
            }
            
            if err != nil {
                print("Wir haben einen Error beim User: \(err?.localizedDescription)")
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
        var labelHeight : CGFloat = 10
        
        if titleCount <= 40 {
            labelHeight = 40
        } else if titleCount <= 100 {
            labelHeight = 80
        } else if titleCount <= 150 {
            labelHeight = 100
        } else if titleCount <= 200 {
            labelHeight = 120
        } else if titleCount > 200 {
            labelHeight = 140
        }
        
        return labelHeight
    }
    
    func setReportView(post: Post) -> (heightConstant:CGFloat, buttonHidden: Bool, labelText: String, backgroundColor: UIColor) {
        
        var reportViewHeightConstraint:CGFloat = 0
        var reportViewButtonInTopBoolean = false
        var reportViewLabelText = ""
        var reportViewBackgroundColor = UIColor.white
        
        if post.report == "normal" {
            reportViewHeightConstraint = 0
            reportViewButtonInTopBoolean = true
        } else {
            reportViewHeightConstraint = 24
            reportViewButtonInTopBoolean = false
            
            switch post.report {
                
            case "opinion":
                reportViewLabelText = "Meinung, kein Fakt"
                reportViewBackgroundColor = UIColor(red:0.27, green:0.00, blue:0.01, alpha:1.0)
            case "sensationalism":
                reportViewLabelText = "Sensationalismus"
                reportViewBackgroundColor = UIColor(red:0.36, green:0.00, blue:0.01, alpha:1.0)
            case "circlejerk":
                reportViewLabelText = "Circlejerk"
                reportViewBackgroundColor = UIColor(red:0.58, green:0.04, blue:0.05, alpha:1.0)
            case "pretentious":
                reportViewLabelText = "Angeberisch"
                reportViewBackgroundColor = UIColor(red:0.83, green:0.05, blue:0.07, alpha:1.0)
            case "edited":
                reportViewLabelText = "Nachbearbeitet"
                reportViewBackgroundColor = UIColor(red:1.00, green:0.40, blue:0.36, alpha:1.0)
            case "ignorant":
                reportViewLabelText = "Schwarz-Weiß-Denken"
                reportViewBackgroundColor = UIColor(red:1.00, green:0.46, blue:0.30, alpha:1.0)
            default:
                reportViewHeightConstraint = 24
            }
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
            //db.setValue(valueForFirestore, forKey: keyForFirestore)
            db.updateData([keyForFirestore:valueForFirestore])
        } else {
            print("konnte nicht geupdatet werden")
        }
    }
    
    func setPostType(fetchedString: String) -> PostType? {
        let postType :PostType?
        
        switch fetchedString {
        case "picture":
            postType = .picture
            return postType
        case "thought":
            postType = .thought
            return postType
        case "link":
            postType = .link
            return postType
        case "event":
            postType = .event
            return postType
        case "repost":
            postType = .repost
            return postType
        default:
            print("Hier stimmt was nicht")
            return PostType.picture
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
}
