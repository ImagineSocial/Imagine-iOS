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
    
    var lastSnapshot: QueryDocumentSnapshot?
    var firstSnapshot: QueryDocumentSnapshot?
    
    var initialDocumentID: String?
    
    var noMorePosts = false
    
    static let shared = FirestoreManager()
    
    func reset() {
        lastSnapshot = nil
        firstSnapshot = nil
    }
}
