//
//  CommunityHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class CommunityHelper {
    
    static let shared = CommunityHelper()
    
    //MARK: - Variables
    
    let db = FirestoreRequest.shared.db
    let handyHelper = HandyHelper.shared
    
    //MARK:- Get Community
    
    func getCommunity(documentID: String, data: [String: Any]) -> Community? {
        
        guard let name = data["name"] as? String,
            let timestamp = data["createDate"] as? Timestamp,
            let OP = data["OP"] as? String
            else {
                print("Der will nicht: \(documentID), mit den Daten: \(data)")
                return nil
        }
        
        
        let community = Community()
        community.id = documentID
        community.title = name
        community.createdAt = timestamp.dateValue()
        community.moderators = [OP]
        community.postCount = data["postCount"] as? Int
        community.imageURL = data["imageURL"] as? String
        community.description = data["description"] as? String
        
        
        if let language = data["language"] as? String {
            if language == "en" {
                community.language = .en
            }
        }

        if let displayType = data["displayOption"] as? String { // Was introduced later on
            community.displayOption = self.getDisplayType(string: displayType)
        }
        
        if let displayNames = data["factDisplayNames"] as? String {
            community.discussionTitles = self.getDisplayNames(string: displayNames)
        }
        
        if let _ = data["isAddOnFirstView"] as? Bool {
            community.initialView = .addOn
        }
        
        return community
    }
    
    func loadCommunity(_ community: Community, completion: @escaping (Community?) -> Void) {
        
        guard let id = community.id else {
            completion(nil)
            return
        }
        
        var collectionRef: CollectionReference!
        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(id)
        
        
        ref.getDocument { [weak self] (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                guard let snap = snap, let self = self, let data = snap.data(), let community = self.getCommunity(documentID: snap.documentID, data: data) else {
                    completion(nil)
                    return
                }
                completion(community)
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
    
    func getDisplayNames(string: String) -> DiscussionTitles {
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
