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
enum PostList {
    case postsFromUser
    case savedPosts
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
    
    let language = LanguageSelection().getLanguage()
    
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
    
    let postHelper = PostHelper.shared
    
    func decode<T: Decodable>(query: Query, completion: @escaping (Result<[T], Error>) -> Void) {
        
        query.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                completion(.failure(error ?? FirestoreError.brokenAppleCredential))
                return
            }
            
            let objects = documents.compactMap { queryDocumentSnapshot -> T? in
                try? queryDocumentSnapshot.data(as: T.self)
            }
            
            completion(.success(objects))
        }
    }
    
    
    func getTheUsersFriend(completion: @escaping ([String]?) -> Void) {
        guard friends == nil else {
            completion(friends)
            return
        }
        
        guard let user = AuthenticationManager.shared.user else {
            completion(nil)
            return
        }
        
        let userRef = FirestoreReference.collectionRef(.users, collectionReference: FirestoreCollectionReference(document: user.uid, collection: "friends"))
        
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
            friends.append(user.uid)
            
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
    
    /*
     The Structure at the moment for the main feed:
     getTheUsersFriend("friends", saved in this View) { // to get the right name for the feed
     getLast15Posts() {
     getFollowedTopicIDs() { //Is called inside "getFollowedTopicPosts"
     getFollowedTopicPosts() {   // They are limited to the last date of the getLast15Posts fetch, if getMore, there is also a startAfter query, so the 15 posts fetched from the main query always limit the topicPosts
     
     
     func orderIt() by createTime and return the posts
     }
     }
     }
     }
     */
    
    
    //MARK: - Main Feed
    func getPostsForMainFeed(getMore: Bool, completion: @escaping ([Post]?) -> Void) {
        
        posts.removeAll()
        
        var postQuery = FirestoreReference.collectionRef(.posts)
        
        if getMore {    // If you want to get More Posts
            if let lastSnap = lastSnap {        // For the next loading batch of 20, that will start after this snapshot
                postQuery = postQuery.start(afterDocument: lastSnap)
                self.startBeforeSnap = lastSnap
            }
        }
        
        FirestoreRequest().decode(query: postQuery) { (result: Result<[Post], Error>) in
            switch result {
            case .success(let posts):
                print("posts: ", posts)
            case .failure(let failure):
                print("failure: ", failure.localizedDescription)
            }
        }

        return
        getTheUsersFriend { _ in // First get the friends to choose which name to fetch
            
            postQuery.getDocuments { [weak self] snap, error in
                
                guard let snap = snap, let self = self else {
                    completion(nil)
                    return
                }
                
                self.lastSnap = snap.documents.last    // Last document for the next fetch cycle
                
                for document in snap.documents {
                    if let post = self.postHelper.addThePost(document: document, isTopicPost: false, language: self.language) {
                        self.posts.append(post)
                    }
                }
                
                if let lastSnap = self.lastSnap {
                    self.getFollowedTopicPosts(startSnap: self.startBeforeSnap, endSnap: lastSnap) { posts in
                        var combinedPosts = self.posts
                        combinedPosts.append(contentsOf: self.posts)
                        let finalPosts = combinedPosts.sorted(by: { $0.createDate > $1.createDate})
                        completion(finalPosts)
                    }
                } else {
                    completion(self.posts)
                }
            }
        }
    }
    
    
    
    func getFollowedTopicPosts(startSnap: QueryDocumentSnapshot?, endSnap: QueryDocumentSnapshot, completion: @escaping ([Post]?) -> Void) {
        
        var topicPosts = [Post]()
        
        var startTimestamp = Timestamp(date: Date()) //now, i.e. the first fetch
        
        if let startSnap = startSnap {  // If there is a startSnap, the fetch starts after that
            let data = startSnap.data()
            
            if let startStamp = data["createTime"] as? Timestamp {
                startTimestamp = startStamp
            }
        }
        
        let collectionRef = FirestoreReference.collectionRef(.topicPosts)
        
        let data = endSnap.data()
        
        self.getFollowedTopicIDs { [weak self] topicIDs in
            
            guard let self = self, let topicIDs = topicIDs, let endTimestamp = data["createTime"] as? Timestamp else {
                completion(nil)
                return
            }
            
            let topicTotalCount = topicIDs.count
            var topicCount = 0
            
            if topicIDs.count == 0 {
                completion(nil)
            }
            
            topicIDs.forEach { topicID in
                
                let ref = collectionRef
                    .whereField("linkedFactID", isEqualTo: topicID)
                    .whereField("createTime", isLessThanOrEqualTo: startTimestamp)
                    .whereField("createTime", isGreaterThanOrEqualTo: endTimestamp)
                
                ref.getDocuments { (snap, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                        topicCount += 1
                    } else {
                        topicCount += 1
                        guard let snap = snap else {
                            return
                        }
                        
                        var postCount = 0
                        
                        for document in snap.documents {
                            postCount += 1
                            
                            if let post = self.postHelper.addThePost(document: document, isTopicPost: true, language: self.language) {
                                topicPosts.append(post)
                            }
                        }
                        
                        if topicCount == topicTotalCount && postCount == snap.documents.count {
                            completion(topicPosts)
                        }
                    }
                }
            }
        }
        
    }
    
    func getFollowedTopicIDs(completion: @escaping ([String]?) -> Void) {
        var topicIDs = [String]()
        guard let user = AuthenticationManager.shared.user else {
            completion(nil)
            return
        }
        
        let topicRef = FirestoreReference.collectionRef(.users, collectionReference: FirestoreCollectionReference(document: user.uid, collection: "topics"))
        
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
    
    
    //MARK: - Saved and User
    func getUserPosts(getMore: Bool, postList: PostList, userUID : String, completion: @escaping ([Post]?) -> Void) {
        
        // check if there are more posts to fetch
        guard morePostsToFetch else {
            print("We already have all posts fetched")
            completion(nil)
            return
        }
        
        posts.removeAll()
        
        var postListReference: String!
        
        switch postList {
        case .postsFromUser:
            postListReference = "posts"
        case .savedPosts:
            postListReference = "saved"
        }
        
        var documentIDsOfPosts = [Post]()
        
        let reference = FirestoreCollectionReference(document: userUID, collection: postListReference)
        var userPostRef = FirestoreReference.collectionRef(.users, collectionReference: reference)
        
        
        // Check if the Feed has been refreshed or the next batch is ordered
        if getMore {
            // For the next loading batch of 20, that will start after this snapshot if it is there
            if let lastSnap = lastSavedPostsSnap {
                
                // I think I have an issue with createDate + .start(afterDocument:) because there are some without date
                userPostRef = userPostRef.start(afterDocument: lastSnap)
                self.initialFetch = false
            }
        } else { // Else you want to refresh the feed
            self.initialFetch = true
        }
        
        
        userPostRef.getDocuments { [weak self] querySnapshot, error in
            
            guard let self = self, let snap = querySnapshot, error == nil else {
                completion(nil)
                return
            }
            
            if snap.documents.count == 0 {    // Hasnt posted or saved anything yet
                let post = Post.nothingPosted
                completion([post])
            } else {
                
                self.checkTheDocumentCountFor(type: .users, documentID: userUID, collectionID: postListReference, newFetchCount: snap.documents.count)
                
                self.lastSavedPostsSnap = snap.documents.last // For the next batch
                
                switch postList {
                case .postsFromUser:
                    for document in snap.documents {
                        let documentID = document.documentID
                        let data = document.data()
                        
                        let post = Post.standard
                        post.documentID = documentID
                        if let _ = data["isTopicPost"] as? Bool {
                            post.isTopicPost = true
                        }
                        if let language = data["language"] as? String {
                            if language == "en" {
                                post.language = .en
                            }
                        }
                        documentIDsOfPosts.append(post)
                    }
                    
                    self.getPostsFromDocumentIDs(posts: documentIDsOfPosts) { [weak self] _ in
                        // Needs to be sorted because the posts are fetched without the date that they were added
                        self?.posts.sort(by: { $0.createDate.compare($1.createDate) == .orderedDescending })
                        completion(self?.posts)
                    }
                case .savedPosts:
                    for document in snap.documents {
                        let documentID = document.documentID
                        let data = document.data()
                        
                        let post = Post.standard
                        post.documentID = documentID
                        if let _ = data["isTopicPost"] as? Bool {
                            post.isTopicPost = true
                        }
                        if let documentID = data["documentID"] as? String {
                            post.documentID = documentID
                        }
                        if let language = data["language"] as? String {
                            if language == "en" {
                                post.language = .en
                            }
                        }
                        documentIDsOfPosts.append(post)
                    }
                    
                    
                    self.getPostsFromDocumentIDs(posts: documentIDsOfPosts) { [weak self] _ in
                        if let self = self {
                            // Needs to be sorted because the posts are fetched without the date that they were added
                            self.posts.sort(by: { $0.createDate.compare($1.createDate) == .orderedDescending })
                            completion(self.posts)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Communities
    
    func getPostsForCommunity(getMore: Bool, community: Community, completion: @escaping ([Post]?) -> Void) {
        
        guard !community.documentID.isEmpty, morePostsToFetch else {
            completion(nil)
            return
        }
        
        self.posts.removeAll()
        
        var ref = FirestoreReference.collectionRef(.topicPosts, collectionReference: FirestoreCollectionReference(document: community.documentID, collection: "posts"))
        
        
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
                self.checkTheDocumentCountFor(type: .topicPosts, documentID: community.documentID, newFetchCount: snap.documents.count)
                
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
                    self.posts.sort(by: { $0.createDate.compare($1.createDate) == .orderedDescending })
                    
                    completion(self.posts)
                }
                
            }
        }
    }
    
    func getPreviewPicturesForCommunity(community: Community, completion: @escaping ([Post]?) -> Void) {
        guard community.documentID != "" else {
            completion(nil)
            return
        }
        
        let ref = FirestoreReference.collectionRef(.topicPosts)
            .whereField("linkedFactID", isEqualTo: community.documentID)
            .whereField("type", isEqualTo: "picture")
            .limit(to: 6)
        
        ref.getDocuments { [weak self] snap, error in
            
            guard let snap = snap, error == nil, !snap.documents.isEmpty else {
                
                completion(nil)
                return
            }
            
            var posts = [Post]()
            
            snap.documents.forEach { document in
                
                if let post = self?.postHelper.addThePost(document: document, isTopicPost: true, language: community.language) {
                    posts.append(post)
                }
            }
            
            completion(posts)
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
        
        var endIndex = posts.count
        var startIndex = 0
        
        if posts.count == 0 {
            completion(self.posts)
        } else {
            
            getTheUsersFriend { _ in // First get the friends to check which name to fetch
                
                posts.forEach { post in
                    var ref: DocumentReference
                    
                    if post.isTopicPost {
                        ref = FirestoreReference.documentRef(.topicPosts, documentID: post.documentID)
                    } else {
                        ref = FirestoreReference.documentRef(.posts, documentID: post.documentID)
                    }
                    
                    ref.getDocument { document, error in
                        guard let document = document, error == nil else {
                            
                            completion(nil)
                            return
                        }
                        
                        
                        if let post = self.postHelper.addThePost(document: document, isTopicPost: post.isTopicPost, language: post.language) {
                            self.posts.append(post)
                            
                            startIndex+=1
                        } else {
                            endIndex-=1
                        }
                        
                        if startIndex == endIndex {
                            completion(self.posts)
                        }
                    }
                }
            }
        }
    }
    
    //MARK:- Stuff
    
    func addFact(factID: String) -> Community {
        let fact = Community()
        fact.documentID = factID
        for topic in self.followedTopicIDs {
            if factID == topic {
                fact.beingFollowed = true
            }
        }
        return fact
    }
    
    func loadPost(post: Post, completion: @escaping (Post?) -> Void) {
        let ref: DocumentReference!
        
        if post.documentID == "" {   // NewAddOnTableVC
            completion(nil)
        }
        
        if post.isTopicPost {
            ref = FirestoreReference.documentRef(.topicPosts, documentID: post.documentID)
        } else {
            ref = FirestoreReference.documentRef(.posts, documentID: post.documentID)
        }
        
        ref.getDocument { snap, error in
            guard let snap = snap, error == nil else {
                completion(nil)
                return
            }
            
            if let fullPost = self.postHelper.addThePost(document: snap, isTopicPost: post.isTopicPost, language: post.language){
                completion(fullPost)
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
