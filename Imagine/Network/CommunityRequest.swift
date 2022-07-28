//
//  CommunityRequest.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

class CommunityRequest {
    
    private let db = FirestoreRequest.shared.db
    private let communityHelper = CommunityHelper.shared
    
    //MARK: - Get Community
    /// Load the fact and return it asynchroniously
    func getCommunity(language: Language, communityID: String, completion: @escaping (Community?) -> Void) {
        
        let ref = FirestoreReference.documentRef(.communities, documentID: communityID, language: language)
        
        ref.getDocument { (doc, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let document = doc, let data = document.data(), let community = self.communityHelper.getCommunity(documentID: document.documentID, data: data) {
                    completion(community)
                } else {
                    print("Error: COuldnt get a community")
                }
            }
        }
    }
}
