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
    
    //MARK:- Variables
    public var displayName = ""
    public var imageURL = ""
    public var userUID = ""
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
    
    //MARK:- Get User
    func getUsername(userID: String, username: @escaping (String?) -> Void) {
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
    
    //MARK:- Get Badges
    func getBadges(returnBadges: @escaping ([String]) -> Void) {
        
        if userUID != "" {
            let ref = db.collection("Users").document(userUID)
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
        } else {
            print("Got no UID for badges")
        }
    }
}
