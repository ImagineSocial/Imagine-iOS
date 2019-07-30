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
        
        var reportViewHeightConstraint:CGFloat = 24
        var reportViewButtonInTopBoolean = false
        var reportViewLabelText = ""
        var reportViewBackgroundColor = UIColor.white
        
        switch post.report {
        case .normal:
            reportViewHeightConstraint = 0
            reportViewButtonInTopBoolean = true
        case .spoiler:
            reportViewLabelText = "Achtung Spoiler"
            reportViewBackgroundColor = .red
        case .opinion:
            reportViewLabelText = "Meinung, kein Fakt"
            reportViewBackgroundColor = UIColor(red:0.27, green:0.00, blue:0.01, alpha:1.0)
        case .sensationalism:
            reportViewLabelText = "Sensationalismus"
            reportViewBackgroundColor = UIColor(red:0.36, green:0.00, blue:0.01, alpha:1.0)
        case .circlejerk:
            reportViewLabelText = "Circlejerk"
            reportViewBackgroundColor = UIColor(red:0.58, green:0.04, blue:0.05, alpha:1.0)
        case .pretentious:
            reportViewLabelText = "Angeberisch"
            reportViewBackgroundColor = UIColor(red:0.83, green:0.05, blue:0.07, alpha:1.0)
        case .ignorant:
            reportViewLabelText = "Schwarz-Weiß-Denken"
            reportViewBackgroundColor = UIColor(red:1.00, green:0.46, blue:0.30, alpha:1.0)
        case .edited:
            reportViewLabelText = "Nachbearbeitet"
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
    
    
    
    func getChats(chatList: @escaping ([Chat]) -> Void ) {
        var chatsList = [Chat]()
        
        if let user = Auth.auth().currentUser {
            let chatsRef = db.collection("Users").document(user.uid).collection("chats")
            
            chatsRef.getDocuments { (snapshot, error) in
                if error == nil {
                    
                    for document in snapshot!.documents {
                        let documentData = document.data()
                        
                        guard let participant = documentData["participant"] as? String else { return }
                        
                        let chat = Chat()
                        chat.documentID = document.documentID
                        chat.participant.userUID = participant
                        if let lastMessageID = documentData["lastReadMessage"] as? String {
                            chat.lastReadMessageUID = lastMessageID
                        }
                        
                        chatsList.append(chat)
                    }
                    chatList(chatsList)
                } else {
                    print("We have an error within the chats: \(error?.localizedDescription ?? "")")
                }
            }
            
        } else {
            // Nobody logged In
        }
    }
    
    func getCountOfUnreadMessages(chatList: [Chat], unreadMessages: @escaping (Int) -> Void ) {
        var count = 0
        
        for chat in chatList {
            let chatsRef = self.db.collection("Chats").document(chat.documentID).collection("threads").order(by: "sentAt", descending: true)
            
            // Already been in this chat at least once
            if let lastReadMessage = chat.lastReadMessageUID {
                
                let lastReadMessageDoc = db.collection("Chats").document(chat.documentID).collection("threads").document(lastReadMessage)
                
                lastReadMessageDoc.getDocument { (document, error) in
                    if let error = error {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        let endingChatsRef = chatsRef.end(beforeDocument: document!)
                        endingChatsRef.getDocuments(completion: { (snap, error) in
                            
                            if let error = error {
                                print("We have an error: \(error.localizedDescription)")
                            } else {
                                let unreadMessageCount = snap!.documents.count
                                
                                count = count+unreadMessageCount
                                
                                unreadMessages(count)
                            }
                        })
                    }
                }
            } else {
                // New chat, not a lastReadMessageUID set
                chatsRef.getDocuments { (snap, error) in
                    if let error = error {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        let unreadMessageCount = snap!.documents.count
                        count = count+unreadMessageCount
                        unreadMessages(count)
                        }
                }
            }
            // Here was unreadMessages(count) but it finished too early
        }
    }
    
}
