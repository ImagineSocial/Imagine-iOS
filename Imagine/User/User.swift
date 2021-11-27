//
//  User.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

public class User {
    
    init(userID: String) {
        self.userID = userID        
    }
    
    //MARK: - Variables
    
    public var userID: String
    public var displayName = ""
    public var imageURL = ""
    public var image = UIImage(named: "default-user")
    public var blocked: [String]?
    public var statusQuote = ""
    
    //Social Media Links
    public var instagramLink: String?
    public var instagramDescription: String?
    public var patreonLink: String?
    public var patreonDescription: String?
    public var youTubeLink: String?
    public var youTubeDescription: String?
    public var twitterLink: String?
    public var twitterDescription: String?
    public var songwhipLink: String?
    public var songwhipDescription: String?
    
    //location
    public var locationName: String?
    public var locationIsPublic = false
    
    private let db = Firestore.firestore()
    
    //MARK: - Get Username
    func getUsername(username: @escaping (String?) -> Void) {
        let ref = db.collection("Users").document(userID)
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap, let data = snap.data() {
                    if let name = data["name"] as? String {
                        username(name)
                    } else {
                        username(nil)
                    }
                } else {
                    username(nil)
                }
            }
        }
    }
    
    //MARK: - Get Badges
    func getBadges(returnBadges: @escaping ([String]) -> Void) {
        
        let ref = db.collection("Users").document(userID)
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let badges = data["badges"] as? [String] {
                            returnBadges(badges)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Get User
    func getUser(isAFriend: Bool, completion: @escaping (User?) -> Void) {
        
        let userRef = db.collection("Users").document(userID)
        
        userRef.getDocument(completion: { (document, err) in
            if let error = err {
                print("We got an error with a user: \(error.localizedDescription)")
                completion(nil)
            } else {
                if let document = document {
                    self.generateUser(isAFriend: isAFriend, document: document, completion: completion)
                }
            }
        })
    }
    
    func generateUser(isAFriend: Bool, document: DocumentSnapshot, completion: @escaping (User?) -> Void) {
        if let docData = document.data() {
            
            if isAFriend {
                let fullName = docData["full_name"] as? String ?? ""
                self.displayName = fullName
            } else {
                let userName = docData["name"] as? String ?? "Username"
                self.displayName = userName
            }
            
            if let instagramLink = docData["instagramLink"] as? String {
                self.instagramLink = instagramLink
                self.instagramDescription = docData["instagramDescription"] as? String
            }
            
            if let patreonLink = docData["patreonLink"] as? String {
                self.patreonLink = patreonLink
                self.patreonDescription = docData["patreonDescription"] as? String
            }
            if let youTubeLink = docData["youTubeLink"] as? String {
                self.youTubeLink = youTubeLink
                self.youTubeDescription = docData["youTubeDescription"] as? String
            }
            if let twitterLink = docData["twitterLink"] as? String {
                self.twitterLink = twitterLink
                self.twitterDescription = docData["twitterDescription"] as? String
            }
            if let songwhipLink = docData["songwhipLink"] as? String {
                self.songwhipLink = songwhipLink
                self.songwhipDescription = docData["songwhipDescription"] as? String
            }
            
            if let locationName = docData["locationName"] as? String {
                self.locationName = locationName
            }
            if let locationIsPublic = docData["locationIsPublic"] as? Bool {
                self.locationIsPublic = locationIsPublic
            }
            
            self.imageURL = docData["profilePictureURL"] as? String ?? ""
            self.statusQuote = docData["statusText"] as? String ?? ""
            self.blocked = docData["blocked"] as? [String] ?? nil
            
            completion(self)
        } else {
            completion(nil)
        }
    }
}
