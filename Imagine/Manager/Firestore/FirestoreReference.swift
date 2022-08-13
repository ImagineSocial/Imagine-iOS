//
//  FirestoreReference.swift
//  Imagine
//
//  Created by Don Malte on 30.05.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum CollectionType: String {
    
    case anonymousPosts, blogPosts, bugs, campaigns, chats, communities, feedback, posts, reports, topTopicData, topicPosts, users, votes, userFeed, communityPosts
    
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
        case .communities, .communityPosts:
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
        case .users, .userFeed:
            return "Users"
        case .votes:
            return "Votes"
        }
    }
    
    var languageString: String? {
        switch self {
        case .campaigns:
            return "campaigns"
        case .communities, .communityPosts:
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
        case .posts, .communityPosts:
            return FirestoreQuery(field: "createdAt", limit: 15)
        default:
            return nil
        }
    }
    
}

struct FirestoreQuery {
    var field: String
    var equalTo: String? = nil
    var descending = true
    var limit: Int?
}

struct FirestoreCollectionReference {
    var document: String
    var collection: String
}

class FirestoreReference {
    
    static let language = LanguageSelection.language
    static let db = Firestore.firestore()
    
    static func isMigrated(type: CollectionType) -> Bool {
        guard language == .de && type == .campaigns else {
            return true
        }
        
        return false
    }
    
    static func collectionRef(_ type: CollectionType, collectionReferences: FirestoreCollectionReference..., queries: FirestoreQuery..., language: Language? = nil) -> Query {
        
        let reference = mainRef(type, collectionReferences: collectionReferences.first, (collectionReferences.count > 1) ? collectionReferences.last : nil, language: language)
        var completeQuery: Query?
        
        // Check if we got a query or a default query
        if !queries.isEmpty || type.defaultQuery != nil {
             if let defaultQuery = type.defaultQuery {
                completeQuery = reference.addQuery(defaultQuery)
            }
            
            queries.forEach { query in
                if let anotherQuery = completeQuery {
                    completeQuery = anotherQuery.addFirestoreQuery(query)
                } else {
                    completeQuery = reference.addQuery(query)
                }
            }
        }
        
        return completeQuery ?? reference
    }
    
    static func documentRef(_ type: CollectionType, documentID: String?, collectionReferences: FirestoreCollectionReference..., language: Language? = nil) -> DocumentReference {
                
        let reference = mainRef(type, collectionReferences: collectionReferences.first, (collectionReferences.count > 1) ? collectionReferences.last : nil, language: language)
        
        guard let documentID = documentID else {
            return reference.document()
        }

        return reference.document(documentID)
    }
    
    // MARK: - Main Ref
    
    static func mainRef(_ type: CollectionType, collectionReferences: FirestoreCollectionReference?..., language: Language? = nil) -> CollectionReference {
        var reference: CollectionReference
                
        let languageSymbol = language?.rawValue ?? self.language.rawValue
        
        if type.gotLanguageSubcollection, let languageString = type.languageString, isMigrated(type: type) {
            reference = db.collection("Data").document(languageSymbol).collection(languageString)
        } else {
            reference = db.collection(type.mainString)
        }
        
        // Custom data for specific collections
        collectionReferences.forEach { collectionReference in
            guard let collectionReference = collectionReference else {
                return
            }

            reference = reference.document(collectionReference.document).collection(collectionReference.collection)
        }
        
        return reference
    }
    
}
