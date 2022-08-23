//
//  Fact.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

enum TopicDisplayType {
    case normal, addMore, showAll
}

enum InitialCommunityView: String, Codable {
    case addOn, discussion, feed
}

class Community: Codable {
    
    // MARK: - Variables
    
    @DocumentID var id: String?
    var title: String?
    var description: String?
    var createdAt: Date?
    var createdBy: String?
    var imageURL: String?
    var arguments: [Argument]?
    var displayOption: DisplayOption = .topic
    var discussionTitles: DiscussionTitles?
    var moderators: [String]?
    var initialView: InitialCommunityView = .feed
    var postCount: Int?
    var popularity: Int?
    var followerCount: Int?
    var follower: [String]?
    var language: Language = .en
        
    
    // MARK: Get Follow Status
    func getFollowStatus(completion: @escaping (Bool) -> Void) {
        guard let userID = AuthenticationManager.shared.user?.uid, let id = id else {
            completion(false)
            return
        }
        
        let collectionReference = FirestoreCollectionReference(document: userID, collection: "topics")
        let ref = FirestoreReference.documentRef(.users, documentID: id, collectionReferences: collectionReference, language: language)
        
        ref.getDocument { document, _ in
            if let document = document {
                completion(document.exists)
            }
        }
    }
}

// MARK: - Follow and unfollow
extension Community {
    
    func followTopic(completion: @escaping (Bool) -> Void) {
        guard let userID = AuthenticationManager.shared.userID, let id = id else {
            completion(false)
            return
        }
        
        let postData = PostData(createdAt: Date(), language: language)
        
        let collectionReference = FirestoreCollectionReference(document: userID, collection: "topics")
        let documentReference = FirestoreReference.documentRef(.users, documentID: id, collectionReferences: collectionReference)
        
        FirestoreManager.uploadObject(object: postData, documentReference: documentReference) { error in
            completion(error == nil)
            
            guard let error = error else {
                return
            }

            print("We have an error following the community: \(error.localizedDescription)")
        }
    }
    
    func unfollowTopic(completion: @escaping (Bool) -> Void) {
        guard let userID = AuthenticationManager.shared.userID else {
            completion(false)
            return
        }
        let collectionReference = FirestoreCollectionReference(document: userID, collection: "topics")
        let documentReference = FirestoreReference.documentRef(.users, documentID: id, collectionReferences: collectionReference)
        
        FirestoreManager.delete(documentReference) { error in
            completion(error == nil)
            
            guard let error = error else {
                
                return
            }

            print("We have an error unfollowing the community: \(error.localizedDescription)")
        }
    }
    
    private func updateFollowCount(follow: Bool) {
        guard let userID = AuthenticationManager.shared.userID, let communityID = id else {
            return
        }
        
        let documentReference = FirestoreReference.documentRef(.communities, documentID: communityID, language: language)
        
        documentReference.updateData([
            "follower" : follow ? FieldValue.arrayUnion([userID]) : FieldValue.arrayRemove([userID])
        ])
    }
}
