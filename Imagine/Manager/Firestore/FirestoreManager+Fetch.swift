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
    
    func getPostsForMainFeed(completion: @escaping ([Post]?) -> Void) {
        
        getPosts(for: .main) { posts in
            guard let lastSnapshot = self.lastSnapshot else {
                completion(nil)
                return
            }

            self.getFollowedTopicPosts(from: self.firstSnapshot, to: lastSnapshot) { topicPosts in
                guard let topicPosts = topicPosts else {
                    returnSortedPosts(posts: posts, completion: completion)
                    return
                }

                guard let posts = posts else {
                    returnSortedPosts(posts: topicPosts, completion: completion)
                    return
                }
                
                let combinedPosts = topicPosts + posts
                returnSortedPosts(posts: combinedPosts, completion: completion)
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
    
    func getPosts(for type: FeedType, completion: @escaping ([Post]?) -> Void) {
        let postQuery = FirestoreReference.collectionRef(.posts)
        
        if let lastSnap = lastSnapshot {
            postQuery.start(atDocument: lastSnap)
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
    
    func getFollowedTopicPosts(from startSnapshot: QueryDocumentSnapshot?, to endSnapshot: QueryDocumentSnapshot, completion: @escaping ([Post]?) -> Void) {
        
        var topicPosts = [Post]()
                
        self.getFollowedTopicIDs { [weak self] topicIDs in
            
            guard let self = self, let topicIDs = topicIDs, !topicIDs.isEmpty else {
                completion(nil)
                return
            }
            
            let topicTotalCount = topicIDs.count
            var topicCount = 0
                        
            topicIDs.forEach { topicID in
                var reference = FirestoreReference.collectionRef(.topicPosts, queries: FirestoreQuery(field: "communityID", equalTo: topicID), FirestoreQuery(field: "createdAt"))
                
                if let startSnapshot = startSnapshot {
                    reference = reference.start(after: [startSnapshot.timestamp()])
                }
                reference = reference.end(before: [endSnapshot.timestamp()])
                
                self.decode(query: reference) { (result: Result<[Post], Error>) in
                    topicCount += 1
                    
                    switch result {
                    case .success(let posts):
                        topicPosts.append(contentsOf: posts)
                    case .failure(let error):
                        print("We have an error: \(error.localizedDescription)")
                    }
                    
                    if topicCount == topicTotalCount {
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
        
        let topicRef = FirestoreReference.collectionRef(.users, collectionReference: FirestoreCollectionReference(document: userID, collection: "topics"))
        
        topicRef.getDocuments { snap, err in
            guard let snap = snap else {
                completion(nil)
                return
            }
            
            let topicIDs = snap.documents.compactMap { $0.documentID }
            
            completion(topicIDs)
        }
    }
    
    func getUserPosts(userID: String, completion: @escaping ([Post]?) -> Void) {
        
        let reference = FirestoreCollectionReference(document: userID, collection: "posts")
        var userPostRef = FirestoreReference.collectionRef(.userFeed, collectionReference: reference)
        
        if let lastSnapshot = lastSnapshot {
            userPostRef = userPostRef.start(afterDocument: lastSnapshot)
        }
        
        decodePostData(reference: userPostRef, completion: completion)
    }
    
    func getSavedPosts(userID: String, completion: @escaping ([Post]?) -> Void) {
    
        let reference = FirestoreCollectionReference(document: userID, collection: "saved")
        var savedPostRef = FirestoreReference.collectionRef(.userFeed, collectionReference: reference)
        
        if let lastSnapshot = lastSnapshot {
            savedPostRef = savedPostRef.start(afterDocument: lastSnapshot)
        }
        
        decodePostData(reference: savedPostRef, completion: completion)
    }
    
    func getCommunityPosts(communityID: String, completion: @escaping ([Post]?) -> Void) {
        
        let reference = FirestoreCollectionReference(document: communityID, collection: "posts")
        var userPostRef = FirestoreReference.collectionRef(.communityPosts, collectionReference: reference)
        
        if let lastSnapshot = lastSnapshot {
            userPostRef = userPostRef.start(afterDocument: lastSnapshot)
        }
        
        decodePostData(reference: userPostRef, completion: completion)
    }
    
    private func decodePostData(reference: Query, completion: @escaping ([Post]?) -> Void) {
        
        guard !noMorePosts else {
            completion(nil)
            return
        }
        
        decode(query: reference) { (result: Result<[PostData], Error>) in
            switch result {
            case .success(let data):
                if data.isEmpty {
                    self.noMorePosts = true
                    
                    let post = Post.nothingPosted
                    completion([post])
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
        
        data.enumerated().forEach { index, post in
            let reference = FirestoreReference.documentRef(post.isTopicPost ? .topicPosts : .posts, documentID: post.id, language: post.language)
                
            decodeSingle(reference: reference) { (result: Result<Post, Error>) in
                switch result {
                case .success(let post):
                    posts.append(post)
                case .failure(let error):
                    print("We have an error: \(error.localizedDescription)")
                }
                
                if index + 1 == data.count {
                    posts = posts.sorted { $0.createdAt > $1.createdAt }
                    completion(posts)
                }
            }
        }
    }
    
    func decode<T: Decodable>(query: Query, completion: @escaping (Result<[T], Error>) -> Void) {
        
        query.getDocuments { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                completion(.failure(error ?? FirestoreError.brokenAppleCredential))
                return
            }
            
            let objects = documents.compactMap { queryDocumentSnapshot -> T? in
                try? queryDocumentSnapshot.data(as: T.self)
            }
            
            self.lastSnapshot = documents.last
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // We need it when we fethc the followedTopics but at the first fetch, it could be, that a topicPost is newer than the firstSnapshot here and then we wouldnt fetch it
                self.firstSnapshot = documents.first
            }
            
            self.activateSubcollections(for: objects)
            completion(.success(objects))
        }
    }
    
    func decodeSingle<T: Decodable>(reference: DocumentReference, completion: @escaping (Result<T, Error>) -> Void) {
        reference.getDocument(as: T.self) { (result: Result<T, Error>) in
            switch result {
            case .success(let object):
                self.activateSubcollections(for: [object])
                completion(.success(object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func activateSubcollections(for objects: [Any]) {
        if let posts = objects as? [Post] {
            posts.forEach { $0.loadUser() }
        }
    }
}

