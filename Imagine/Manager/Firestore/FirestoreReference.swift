//
//  FirestoreReference.swift
//  Imagine
//
//  Created by Don Malte on 30.05.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase

enum CollectionType: String {
    
    case anonymousPosts, blogPosts, bugs, campaigns, chats, communities, feedback, posts, reports, topTopicData, topicPosts, users, votes
    
    var gotLanguageSubcollection: Bool {
        self.languageString != nil
    }
    
    var mainString: String {
        switch self {
        case .anonymousPosts:
            return "AnonymousString"
        case .blogPosts:
            return "BlogPosts"
        case .bugs:
            return "Bugs"
        case .campaigns:
            return "Campaigns"
        case .chats:
            return "Chats"
        case .communities:
            return "Facts"
        case .feedback:
            return "Feedback"
        case .posts:
            return "Posts"
        case .reports:
            return "Reports"
        case .topTopicData:
            return "TopTopicData"
        case .topicPosts:
            return "TopicPosts"
        case .users:
            return "Users"
        case .votes:
            return "Votes"
        }
    }
    
    var languageString: String? {
        switch self {
        case .campaigns:
            return "campaigns"
        case .communities:
            return "topics"
        case .posts:
            return "posts"
        case .topTopicData:
            return "topTopicData"
        case .topicPosts:
            return "topicPosts"
        case .votes:
            return "votes"
        default:
            return nil
        }
    }
    
    var defaultQuery: FirestoreQuery? {
        switch self {
        case .posts, .users, .topicPosts:
            return FirestoreQuery(field: "createTime", limit: 15)
        default:
            return nil
        }
    }
    
}

struct FirestoreQuery {
    var field: String
    var descending = true
    var limit: Int?
}

struct FirestoreCollectionReference {
    var document: String
    var collection: String
}

class FirestoreReference {
    
    static let language = LanguageSelection().getLanguage()
    static let db = Firestore.firestore()
    
    static func collectionRef(_ type: CollectionType, collectionReference: FirestoreCollectionReference? = nil, query: FirestoreQuery? = nil) -> Query {
        
        let reference = mainRef(type, collectionReference: collectionReference)
        
        // Check if we got a query or a default query
        if let query = query ?? type.defaultQuery {
            reference.order(by: query.field, descending: query.descending)
            
            if let limit = query.limit {
                reference.limit(to: limit)
            }
        }
        
        return reference
    }
    
    static func documentRef(_ type: CollectionType, documentID: String, collectionReference: FirestoreCollectionReference? = nil) -> DocumentReference {
        
        let reference = mainRef(type, collectionReference: collectionReference)
        
        return reference.document(documentID)
    }
    
    // MARK: - Main Ref
    
    static func mainRef(_ type: CollectionType, collectionReference: FirestoreCollectionReference? = nil) -> CollectionReference {
        var reference: CollectionReference
        
        // The german language got no subfolder for the data because of the bad database structure.
        switch language {
        case .german:
            reference = db.collection(type.mainString)
        default:
            if type.gotLanguageSubcollection, let languageString = type.languageString {
                reference = db.collection("Data").document("en").collection(languageString)
            } else {
                reference = db.collection(type.mainString)
            }
        }
        
        // Custom data for specific collections
        if let collectionReference = collectionReference {
            reference.document(collectionReference.document).collection(collectionReference.collection)
        }
        
        return reference
    }
    
}
