//
//  Message.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

//import Foundation
//import Firebase
//import FirebaseFirestore
//import MessengerKit
//
//
//class Message: MSGMessage {
//    
////    var messageId: String {
////        return id ?? UUID().uuidString
////    }
//    
//    var image: UIImage? = nil
//    var downloadURL: URL? = nil
//    var messageBody : String? = nil
//    
//    
////    init(user: User, image: UIImage) {
////        sender = Sender(id: user.uid, displayName: AppSettings.displayName)
////        self.image = image
////        content = ""
////        sentDate = Date()
////        id = nil
////    }
//    
//    init?(document: QueryDocumentSnapshot) {
//        let data = document.data()
//        
//        guard let sentAt = data["sentAt"] as? Timestamp else {
//            return nil
//        }
//        guard let userID = data["userID"] as? String else {
//            return nil
//        }
//        guard let senderName = data["senderName"] as? String else {
//            return nil
//        }
//        
//        let messageID = document.documentID
//        
////        self.sentDate = sentDate
////        sender = Sender(id: senderID, displayName: senderName)
//        
//        if let body = data["body"] as? String {
//            self.messageBody = body
//            downloadURL = nil
//        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
//            downloadURL = url
//            messageBody = ""
//        } else {
//            return nil
//        }
//    }
//    
//}
//
//extension Message: DatabaseRepresentation {
//    
//    var representation: [String : Any] {
//        var rep: [String : Any] = [
//            "sentAt": sentAt as? Timestamp,
//            "userID": ,
//            "senderName": sender.displayName
//        ]
//        
//        if let url = downloadURL {
//            rep["url"] = url.absoluteString
//        } else {
//            rep["content"] = content
//        }
//        
//        return rep
//    }
//    
//}
//
//protocol DatabaseRepresentation {
//    var representation: [String: Any] { get }
//}
//
