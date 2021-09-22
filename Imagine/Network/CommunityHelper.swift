//
//  CommunityHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class CommunityHelper {
    
    //MARK:- Variables
    let db = Firestore.firestore()
    let handyHelper = HandyHelper()
    let user = Auth.auth().currentUser
    
    //MARK:- Get Community
    
    func getCommunity(currentUser: Firebase.User?, documentID: String, data: [String: Any]) -> Community? {
        
        guard let name = data["name"] as? String,
            let createTimestamp = data["createDate"] as? Timestamp,
            let OP = data["OP"] as? String
            else {
                print("Der will nicht: \(documentID), mit den Daten: \(data)")
                return nil
        }
        
        let stringDate = self.handyHelper.getStringDate(timestamp: createTimestamp)
        
        let community = Community()
        community.documentID = documentID
        community.title = name
        community.createDate = stringDate
        community.moderators.append(OP)  //Later there will be more moderators, so it is an array
        
        if let postCount = data["postCount"] as? Int {
            community.postCount = postCount
        }
        
        if let follower = data["follower"] as? [String] {
            community.followerCount = follower.count
            if let user = currentUser {
                for userID in follower {
                    if userID == user.uid {
                        community.beingFollowed = true
                    }
                }
            }
        }
        
        if let language = data["language"] as? String {
            if language == "en" {
                community.language = .english
            }
        }
        
        if let imageURL = data["imageURL"] as? String { // Not mandatory (in fact not selectable)
            community.imageURL = imageURL
        }
        if let description = data["description"] as? String {   // Was introduced later on
            community.description = description
        }
        if let displayType = data["displayOption"] as? String { // Was introduced later on
            community.displayOption = self.getDisplayType(string: displayType)
        }
        
        if let displayNames = data["factDisplayNames"] as? String {
            community.factDisplayNames = self.getDisplayNames(string: displayNames)
        }
        
        if let isAddOnFirstView = data["isAddOnFirstView"] as? Bool {
            community.isAddOnFirstView = isAddOnFirstView
        }
        
        community.fetchComplete = true
        return community
    }
    
    func loadCommunity(fact: Community, loadedFact: @escaping (Community?) -> Void) {
        
        if fact.documentID == "" {
            loadedFact(nil)
        }
        
        var collectionRef: CollectionReference!
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(fact.documentID)
        
        
        ref.getDocument { [weak self] (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let self = self {
                        if let data = snap.data() {
                            if let fact = self.getCommunity(currentUser: self.user, documentID: snap.documentID, data: data) {
                                loadedFact(fact)
                            } else {
                                loadedFact(nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getDisplayType(string: String) -> DisplayOption {
        switch string {
        case "topic":
            return .topic
        default:
            return .discussion
        }
    }
    
    func getDisplayNames(string: String) -> FactDisplayName {
        switch string {
        case "confirmDoubt":
            return .confirmDoubt
        case "advantage":
            return .advantageDisadvantage
        default:
            return .proContra
        }
    }
    
}
