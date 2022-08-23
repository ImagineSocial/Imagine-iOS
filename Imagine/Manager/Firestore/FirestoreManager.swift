//
//  FirestoreManager.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum FeedType {
    case main, user, saved
}

struct PostData: Codable {
    @DocumentID var id: String?
    var createdAt: Date
    var userID: String?
    var language: Language
    var isTopicPost: Bool = false
}

enum PostDataType: String, Codable {
    case topic
}

class FirestoreManager {
    
    static let db = Firestore.firestore()
    
    /** When we fetch posts, we paginate them with these snapshots.
     
     When we retrive posts for the main feed, we use the date of the last post as a limit for the topicPosts to fetch.
     That means we look for relevant topicPosts in this timeframe.
     In the first page of posts, there is only an endBefore timestamp. Every time after this, there is also a startAfter timestamp to fetch only the relevant topicPosts.
     
     */
    var endBeforeSnapshot: QueryDocumentSnapshot?
    var startAfterSnapshot: QueryDocumentSnapshot?
        
    var initialDocumentID: String?
    
    var noMorePosts = false
    
    static let shared = FirestoreManager()
    
    func reset() {
        endBeforeSnapshot = nil
        startAfterSnapshot = nil
    }
}
