//
//  FirestoreManager+Post.swift
//  Imagine
//
//  Created by Don Malte on 25.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

// This enum differentiates between savedPosts or posts for the "getTheSavedPosts" function
enum UserPostType {
    case user
    case saved
}

enum FirestoreError: Error {
    case notAuthorized
    case brokenAppleCredential
}

class FirestoreRequest {
    
    static let shared = FirestoreRequest()
    
    // MARK: - Variables
    
    var posts = [Post]()
    let db = Firestore.firestore()
    
    let language = LanguageSelection.language
    
    var initialFetch = true
    
    var lastSnap: QueryDocumentSnapshot?
    var startBeforeSnap: QueryDocumentSnapshot?
    var lastSavedPostsSnap: QueryDocumentSnapshot?
    var lastFeedPostSnap: QueryDocumentSnapshot?
    
    var friends: [String]?
    var followedTopicIDs = [String]()
    
    /* These two variables are here to make sure that we just fetch as many as there are documents and dont start at the beginning again  */
    var morePostsToFetch = true
    var totalCountOfPosts = 0
    var alreadyFetchedCount = 0
        
    func getTheUsersFriend(completion: @escaping ([String]?) -> Void) {
        guard friends == nil else {
            completion(friends)
            return
        }
        
        guard let userID = AuthenticationManager.shared.user?.uid else {
            completion(nil)
            return
        }
        
        let userRef = FirestoreReference.collectionRef(.users, collectionReference: FirestoreCollectionReference(document: userID, collection: "friends"))
        
        userRef.getDocuments { snap, error in
            guard let snaps = snap, error == nil else {
                completion(nil)
                return
            }
            var friends = [String]()
            for document in snaps.documents {
                friends.append(document.documentID)
            }
            
            //Add yourself to the list so you see your full name in the feed
            friends.append(userID)
            
            self.friends = friends
            
            completion(friends)
        }
    }
    
    func checkIfOPIsAFriend(userUID: String) -> Bool {
        if let friends = self.friends {
            for friend in friends {
                if friend == userUID {
                    return true
                }
            }
            return false
        } else {
            return false
        }
    }
    
    
    func getFollowedTopicIDs(completion: @escaping ([String]?) -> Void) {
        var topicIDs = [String]()
        guard let userID = AuthenticationManager.shared.user?.uid else {
            completion(nil)
            return
        }
        
        let topicRef = FirestoreReference.collectionRef(.users, collectionReference: FirestoreCollectionReference(document: userID, collection: "topics"))
        
        topicRef.getDocuments { (snap, err) in
            guard let snap = snap else {
                completion(topicIDs)
                return
            }
            for document in snap.documents {
                topicIDs.append(document.documentID)
            }
            
            self.followedTopicIDs = topicIDs
            completion(topicIDs)
        }
    }
    
    
    //MARK: - Communities
    
    func getPostsForCommunity(getMore: Bool, community: Community, completion: @escaping ([Post]?) -> Void) {
        
        guard let communityID = community.id, morePostsToFetch else {
            completion(nil)
            return
        }
        
        self.posts.removeAll()
        
        var ref = FirestoreReference.collectionRef(.topicPosts, collectionReference: FirestoreCollectionReference(document: communityID, collection: "posts"))
        
        
        var documentIDsOfPosts = [Post]()
        
        // Check if the Feed has been refreshed or the next batch is ordered
        if getMore, let lastSnap = lastFeedPostSnap {
            // For the next loading batch of 20, that will start after this snapshot if it is there
            // I think I have an issue with createDate + .start(afterDocument:) because there are some without date
            ref = ref.start(afterDocument: lastSnap)
        }
        
        ref.getDocuments { [weak self] snap, error in
            guard let self = self, let snap = snap, error == nil else {
                
                print("We have an error: \(String(describing: error?.localizedDescription))")
                return
            }
            
            if snap.documents.count == 0 {    // Hasnt posted or saved anything yet
                let post = Post.nothingPosted
                completion([post])
            } else {
                
                //Prepare the next batch
                self.checkTheDocumentCountFor(type: .topicPosts, documentID: communityID, newFetchCount: snap.documents.count)
                
                self.lastFeedPostSnap = snap.documents.last // For the next batch
                
                // Get right post objects for next fetch
                for document in snap.documents {
                    let documentID = document.documentID
                    let data = document.data()
                    
                    let post = Post.standard
                    post.documentID = documentID
                    post.language = community.language
                    
                    if let _ = data["type"] as? String {    // Sort between normal and "JustTopic" Posts
                        post.isTopicPost = true
                    }
                    
                    documentIDsOfPosts.append(post)
                }
                
                self.getPostsFromDocumentIDs(posts: documentIDsOfPosts) { [weak self] _ in    // First fetch the normal Posts, then the "JustTopic" Posts
                    guard let self = self else { return }
                    self.posts.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedDescending })
                    
                    completion(self.posts)
                }
                
            }
        }
    }
    
    func getPreviewPicturesForCommunity(community: Community, completion: @escaping ([Post]?) -> Void) {
        guard let communityID = community.id else {
            completion(nil)
            return
        }
        
        let query = FirestoreReference.collectionRef(.topicPosts)
            .whereField("communityID", isEqualTo: communityID)
            .whereField("type", isEqualTo: "picture")
            .limit(to: 6)
        
        FirestoreManager.shared.decode(query: query) { (result: Result<[Post], Error>) in
            switch result {
            case .success(let posts):
                completion(posts)
            case .failure(let error):
                print("We have an error fetching previewPosts: \(error.localizedDescription)")
            }
        }
    }
    
    
    func checkTheDocumentCountFor(type: CollectionType, documentID: String, collectionID: String = "posts", newFetchCount: Int) {
        
        self.alreadyFetchedCount += newFetchCount
        
        let ref = FirestoreReference.collectionRef(type, collectionReference: FirestoreCollectionReference(document: documentID, collection: collectionID))
        
        ref.getDocuments { querySnap, error in
            
            guard let querySnap = querySnap else {
                print("We have an error: \(error?.localizedDescription ?? "")")
                return
            }
            
            let wholeCollectionDocumentCount = querySnap.documents.count
            
            self.totalCountOfPosts = wholeCollectionDocumentCount
            
            if wholeCollectionDocumentCount <= self.alreadyFetchedCount {
                self.morePostsToFetch = false
            }
        }
    }
    
    // MARK: - Get Posts from DocumentIDs
    func getPostsFromDocumentIDs(posts: [Post], completion: @escaping ([Post]?) -> Void) {
        
        var errorCount = 0
        
        if posts.count == 0 {
            completion(self.posts)
        } else {
            posts.enumerated().forEach { index, post in
                let documentReference = FirestoreReference.documentRef(post.isTopicPost ? .topicPosts : .posts, documentID: post.documentID)
                
                FirestoreManager.shared.decodeSingle(reference: documentReference) { (result: Result<Post, Error>) in
                    switch result {
                    case .success(let post):
                        self.posts.append(post)
                    case .failure(let error):
                        print("We have an error: \(error.localizedDescription)")
                        errorCount += 1
                    }
                    
                    if index == self.posts.count + errorCount {
                        completion(self.posts)
                    }
                }
            }
        }
    }
    
    //MARK:- Stuff
    
    func loadPost(post: Post, completion: @escaping (Post?) -> Void) {
    
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
    
    func getChatUser(uid: String, sender: Bool, completion: @escaping (ChatUser?) -> Void) {
        
        let userRef = FirestoreReference.documentRef(.users, documentID: uid)
        
        userRef.getDocument{ document, error in
            guard let document = document,
                  let docData = document.data(),
                  error == nil,
                  let name = docData["name"] as? String,
                  let surname = docData["surname"] as? String else {
                
                completion(nil)
                return
            }
            
            let chatUser = ChatUser(displayName: "\(name) \(surname)", avatar: nil, avatarURL: nil, isSender: sender)
            
            if let imageURL = docData["profilePictureURL"] as? String, let url = URL(string: imageURL) {
                chatUser.avatarUrl = url
            }
            
            completion(chatUser)
        }
    }
    
    
    
    // MARK: - NotifyMalte
    
    func notifyMalte(documentID: String, isTopicPost: Bool) {
        let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
        let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
        let notificationData: [String: Any] = ["type": "message", "message": "Wir haben einen Link ohne URLPreview", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "postID": documentID, "isTopicPost": isTopicPost]
        
        notificationRef.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
}
