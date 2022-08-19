//
//  FirestoreManager+Fetch.swift
//  Imagine
//
//  Created by Don Malte on 12.06.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

extension FirestoreManager {
    
    // MARK: Main Feed
    
    func getPostsForMainFeed(completion: @escaping ([Post]?) -> Void) {
        
        getMainPosts() { posts in
            guard let lastSnapshot = self.endBeforeSnapshot else {
                completion(nil)
                return
            }

            // Some explanation how this works is next to the endBeforeSnapshot object in the FirestoreManager main file.
            self.getFollowedTopicPosts(to: lastSnapshot) { topicPosts in
                guard let topicPosts = topicPosts else {
                    returnSortedPosts(posts: posts, completion: completion)
                    return
                }

                guard let posts = posts else {
                    returnSortedPosts(posts: topicPosts, completion: completion)
                    return
                }
                
                returnSortedPosts(posts: topicPosts + posts, completion: completion)
            }
            

            func returnSortedPosts(posts: [Post]?, completion: @escaping ([Post]?) -> Void) {
                guard let posts = posts else {
                    completion(nil)
                    return
                }

                completion(posts.sorted(by: { $0.createdAt > $1.createdAt}))
            }
        }
    }
    
    func getMainPosts(completion: @escaping ([Post]?) -> Void) {
        var postQuery = FirestoreReference.collectionRef(.posts)
        
        if let lastSnapshot = endBeforeSnapshot {
            postQuery = postQuery.start(afterDocument: lastSnapshot)
        }
        
        decode(query: postQuery) { (result: Result<[Post], Error>) in
            switch result {
            case .success(let posts):
                print("posts: ", posts)
                completion(posts)
            case .failure(let failure):
                print("failure: ", failure.localizedDescription)
            }
        }
    }
    
    func getFollowedTopicPosts(to endSnapshot: QueryDocumentSnapshot, completion: @escaping ([Post]?) -> Void) {
        
        var topicPosts = [Post]()
                
        self.getFollowedTopicIDs { [weak self] topicIDs in
            
            guard let self = self, let topicIDs = topicIDs, !topicIDs.isEmpty else {
                completion(nil)
                return
            }
            
            let topicTotalCount = topicIDs.count
            var topicCount = 0
                        
            topicIDs.forEach { topicID in
                var query = FirestoreReference.collectionRef(.topicPosts, queries: FirestoreQuery(field: "communityID", equalTo: topicID), FirestoreQuery(field: "createdAt"))
                
                if let firstSnapshot = self.startAfterSnapshot {
                    query = query.start(after: [firstSnapshot.timestamp()])
                    print("## QueryDebug Start after: \(firstSnapshot.timestamp().dateValue())")
                }
                query = query.end(before: [endSnapshot.timestamp()])
                print("## QueryDebug End before: \(endSnapshot.timestamp().dateValue())")
                
                self.decode(query: query, saveSnapshots: false) { (result: Result<[Post], Error>) in
                    topicCount += 1
                    
                    switch result {
                    case .success(let posts):
                        topicPosts.append(contentsOf: posts)
                    case .failure(let error):
                        print("We have an error: \(error.localizedDescription)")
                    }
                    
                    if topicCount == topicTotalCount {
                        self.startAfterSnapshot = self.testSnapshot
                        completion(topicPosts.isEmpty ? nil : topicPosts)
                    }
                }
            }
        }
    }
    
    func getFollowedTopicIDs(completion: @escaping ([String]?) -> Void) {
        guard let userID = AuthenticationManager.shared.userID else {
            completion(nil)
            return
        }
        
        let topicRef = FirestoreReference.collectionRef(.users, collectionReferences: FirestoreCollectionReference(document: userID, collection: "topics"))
        
        topicRef.getDocuments { snap, err in
            guard let snap = snap else {
                completion(nil)
                return
            }
            
            let topicIDs = snap.documents.compactMap { $0.documentID }
            
            completion(topicIDs)
        }
    }
    
    // MARK: User Feed
    func getUserPosts(userID: String, completion: @escaping ([Post]?) -> Void) {
        
        let reference = FirestoreCollectionReference(document: userID, collection: "posts")
        var userPostRef = FirestoreReference.collectionRef(.userFeed, collectionReferences: reference)
        
        if let lastSnapshot = endBeforeSnapshot {
            userPostRef = userPostRef.start(afterDocument: lastSnapshot)
        }
                
        decodePostData(reference: userPostRef, completion: completion)
    }
    
    func getSavedPosts(userID: String, completion: @escaping ([Post]?) -> Void) {
    
        let reference = FirestoreCollectionReference(document: userID, collection: "saved")
        var savedPostRef = FirestoreReference.collectionRef(.userFeed, collectionReferences: reference)
        
        if let lastSnapshot = endBeforeSnapshot {
            savedPostRef = savedPostRef.start(afterDocument: lastSnapshot)
        }
        
        decodePostData(reference: savedPostRef, completion: completion)
    }
    
    
    // MARK: Community Feed
    func getCommunityPosts(communityID: String?, completion: @escaping ([Post]?) -> Void) {
        
        guard let communityID = communityID else {
            completion(nil)
            return
        }
        
        let reference = FirestoreCollectionReference(document: communityID, collection: "posts")
        var userPostRef = FirestoreReference.collectionRef(.communityPosts, collectionReferences: reference)
        
        if let lastSnapshot = endBeforeSnapshot {
            userPostRef = userPostRef.start(afterDocument: lastSnapshot)
        }
        
        decodePostData(reference: userPostRef, completion: completion)
    }
    

    // MARK: Fetch Posts from PostData
    
    private func decodePostData(reference: Query, completion: @escaping ([Post]?) -> Void) {
        
        guard !noMorePosts else {
            completion(nil)
            return
        }
        
        decode(query: reference) { (result: Result<[PostData], Error>) in
            switch result {
            case .success(let data):
                guard !data.isEmpty else {
                    self.noMorePosts = true
                    
                    completion([Post.nothingPosted])
                    return
                }
                
                self.loadPostsFromData(data: data, completion: completion)
            case .failure(let error):
                print("We have an error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    func loadPostsFromData(data: [PostData], completion: @escaping ([Post]?) -> Void) {
        
        guard !data.isEmpty else {
            completion(nil)
            return
        }
                
        var posts = [Post]()
        
        // Check if the object was already fetched or set it if none were set
        if initialDocumentID == nil, let firstDocumentID = data.first?.id {
            initialDocumentID = firstDocumentID
        } else if let documentID = initialDocumentID {
            if data.contains(where: { $0.id == documentID }) {
                noMorePosts = true
                completion(nil)
            }
        }
        
        var failureIndex = 0
        
        data.enumerated().forEach { index, postData in
            let reference = FirestoreReference.documentRef(postData.isTopicPost ? .topicPosts : .posts, documentID: postData.id, language: postData.language)
                
            decodeSingle(reference: reference) { (result: Result<Post, Error>) in
                switch result {
                case .success(let post):
                    posts.append(post)
                case .failure(let error):
                    failureIndex += 1
                    print("We have an error: \(error.localizedDescription)")
                }
                
                if (posts.count + failureIndex) == data.count {
                    posts = posts.sorted { $0.createdAt > $1.createdAt }
                    completion(posts)
                }
            }
        }
    }
    
    
    // MARK: Fetch Posts from DocumentIDs
    
    static func getPostsFromIDs(posts: [Post], completion: @escaping ([Post]?) -> Void) {
        
        guard !posts.isEmpty else {
            completion(nil)
            return
        }
        
        var errorCount = 0
        var fetchedPosts = [Post]()
        
        posts.forEach { post in
            let documentReference = FirestoreReference.documentRef(post.isTopicPost ? .topicPosts : .posts, documentID: post.documentID)
            
            FirestoreManager.shared.decodeSingle(reference: documentReference) { (result: Result<Post, Error>) in
                switch result {
                case .success(let post):
                    fetchedPosts.append(post)
                case .failure(let error):
                    print("We have an error: \(error.localizedDescription)")
                    errorCount += 1
                }
                
                if fetchedPosts.count == posts.count + errorCount {
                    completion(fetchedPosts)
                }
            }
        }
    }
        
    static func getSinglePostFromID(post: Post, completion: @escaping (Post?) -> Void) {
    
        if post.documentID == nil {   // NewAddOnTableVC
            completion(nil)
        }
        
        let ref = FirestoreReference.documentRef(post.isTopicPost ? .topicPosts : .posts, documentID: post.documentID)
        
        FirestoreManager.shared.decodeSingle(reference: ref) { (result: Result<Post, Error>) in
            switch result {
            case .success(let post):
                completion(post)
            case .failure(let error):
                print("We have an error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}

