//
//  User.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

public class User: Codable {
    
    init(userID: String) {
        self.userID = userID        
    }
    
    //MARK: - Variables
    
    public var userID: String
    public var displayName: String?
    public var imageURL: String?
    public var blocked: [String]?
    public var statusQuote: String?
    
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
    
    
    //MARK: - Get Username
    
    func getUsername(username: @escaping (String?) -> Void) {
        
        let ref =  FirestoreRequest.shared.db.collection("Users").document(userID)
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
        
        let ref = FirestoreRequest.shared.db.collection("Users").document(userID)
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
        let userRef = FirestoreRequest.shared.db.collection("Users").document(userID)
        
        userRef.getDocument(completion: { (document, err) in
            if let error = err {
                print("We got an error with a user: \(error.localizedDescription)")
                completion(nil)
            } else {
                if let document = document {
                    AuthenticationManager.shared.generateUser(document: document, completion: completion)
                }
            }
        })
    }
}
