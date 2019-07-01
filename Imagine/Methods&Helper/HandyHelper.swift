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
                    print("Wir haben einen Error beim User: \(err?.localizedDescription)")
                }
            })
        }
    }
}
