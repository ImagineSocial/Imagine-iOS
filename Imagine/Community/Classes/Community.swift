//
//  Fact.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

enum TopicDisplayType {
    case normal
    case addMore
    case showAll
}

class Community {
    
    //MARK:- Variables
    var title = ""
    var createDate = ""
    var documentID = ""
    var imageURL = ""
    var description = ""
    var arguments: [Argument] = []
    var fetchComplete = false
    var displayOption: DisplayOption = .discussion
    var factDisplayNames: FactDisplayName?
    var beingFollowed = false
    var moderators = [String]()     //Later there will be more moderators, so it is an array
    var isAddOnFirstView = false
    var postCount = 0
    var followerCount = 0
    var language: Language = .german
    
    // AddOn Description For the linked Fact/Discussion/Topic
    var addOnTitle: String?
    
    private let db = FirestoreRequest.shared.db
    
    //MARK:
    
    //MARK:- Get Follow Status
    func getFollowStatus(isFollowed: @escaping (Bool) -> Void) {
        if let user = AuthenticationManager.shared.user , documentID != "" {
            let ref = db.collection("Users").document(user.uid).collection("topics").document(documentID)
            
            ref.getDocument { (document, err) in
                if let document = document {
                    if document.exists {
                        isFollowed(true)
                    } else {
                        isFollowed(false)
                    }
                }
            }
        } else {
            isFollowed(false)
        }
    }
}
