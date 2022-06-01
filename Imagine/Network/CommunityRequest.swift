//
//  CommunityRequest.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase

class CommunityRequest {
    
    private let db = FirestoreRequest.shared.db
    private let communityHelper = CommunityHelper.shared
    
    //MARK:- Get Community
    ///Load the fact and return it asynchroniously
    func getCommunity(language: Language, community: Community, beingFollowed: Bool, completion: @escaping (Community) -> Void) {
        
        if community.documentID != "" {
            
            var collectionRef: CollectionReference!
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(community.documentID)
            ref.getDocument { (doc, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    //                    if self == nil {
                    //                        print("Cant get document \(community.documentID) because self isnt there")
                    //                    } // AddOnCollectionVC gets deinitialized though, does that mean "weak self" is not necessar here? For the post Objects it is!
                    if let document = doc, let data = document.data() {
                        let user = Auth.auth().currentUser
                        
                        if let community = self.communityHelper.getCommunity(currentUser: user, documentID: document.documentID, data: data) {
                            completion(community)
                        } else {
                            print("Error: COuldnt get a community")
                        }
                    }
                }
            }
        }
    }
}
