//
//  Post.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct PostDesignOption: Codable {
    var hideProfilePicture = false
    var anonymousName: String?
}

struct PostImage: Codable {
    var url: String
    var height: Double = 0
    var width: Double = 0
    var thumbnailUrl: String?
}

class Post: Codable {
    
    init(type: PostType, title: String, createdAt: Date) {
        self.type = type
        self.title = title
        self.createdAt = createdAt
    }
    
    // MARK: Variables
    
    @DocumentID var documentID: String?
    var type: PostType
    var title: String
    var createdAt: Date
    var image: PostImage?
    var images: [PostImage]?
    var description: String?
    var link: Link?
    var report = ReportType.normal
    var repostDocumentID: String?
    var commentCount = 0
    var anonym = false
    var userID: String? // This is set in the database
    var votes = Votes()
    var newUpvotes: Votes?
    var repost: Post?
    var communityID: String?
    var addOnTitle: String?    // Description in the OptionalInformation Section in the topic area
    var isTopicPost = false // Just postet in a topic, not in the main feed
    var language: Language = .de
    var options: PostDesignOption?
    var location: Location?
    var tags: [String]?
    var notificationRecipients: [String]?
    
    var survey: Survey?
    var community: Community?
    var user: User?     // This is the loaded user
    
    static var standard: Post {
        Post(type: .picture, title: "", createdAt: Date())
    }
    
    static var nothingPosted: Post {
        Post(type: .nothingPostedYet, title: "", createdAt: Date())
    }
    
    // MARK: User
    
    func loadUser() {
        guard let userID = userID else { return }

        let user = User(userID: userID)
        user.loadUser { user in
            self.user = user
        }
    }
    
    // MARK: Repost
    
    func getRepost(completion: @escaping (Post) -> Void) {
        
        guard let repost = repost, let repostID = repost.documentID else { return }
        
        let postRef = FirestoreReference.documentRef(repost.isTopicPost ? .topicPosts : .posts, documentID: repostID)
        
        FirestoreManager.shared.decodeSingle(reference: postRef) { (result: Result<Post, Error>) in
            switch result {
            case .success(let post):
                completion(post)
            case .failure(let error):
                print("We have an error: \(error.localizedDescription)")
            }
        }
    }
    
    func checkIfSaved(completion: @escaping (Bool) -> Void ) {
        guard let documentID = documentID, let userID = AuthenticationManager.shared.userID else {
            completion(false)
            return
        }
        
        let savedReference = FirestoreCollectionReference(document: userID, collection: "saved")
        let ref = FirestoreReference.documentRef(.users, documentID: documentID, collectionReferences: savedReference)
        
        ref.getDocument { document, error in
            guard let document = document, document.exists else {
                completion(false)
                return
            }

            completion(true)
        }
    }
    
    func savePost(completion: @escaping (Bool) -> Void) {
        guard let userID = AuthenticationManager.shared.userID, let documentID = self.documentID else {
            completion(false)
            return
        }
        
        let ref = FirestoreReference.documentRef(.users, documentID: documentID, collectionReferences: FirestoreCollectionReference(document: userID, collection: "saved"))
        
        let data = PostData(createdAt: Date(), userID: userID, language: language, isTopicPost: isTopicPost)
        
        FirestoreManager.uploadObject(object: data, documentReference: ref) { error in
            if let error = error {
                print("We have an error saving this post: \(error.localizedDescription)")
                completion(false)
                return
            }
            print("Successfully saved")
            completion(true)
        }
    }
    
    func registerVote(for type: VoteType) {
        
        switch type {
        case .thanks:
            votes.thanks += 1
        case .wow:
            votes.wow += 1
        case .ha:
            votes.ha += 1
        case .nice:
            votes.nice += 1
        }
        
        uploadVote()
    }
    
    
    private func uploadVote() {
        guard let documentID = self.documentID else { return }
        
        let reference = FirestoreReference.documentRef(isTopicPost ? .topicPosts : .posts, documentID: documentID)
        
        FirestoreManager.uploadObject(object: getUploadPost(), documentReference: reference) { error in
            guard let error = error else {
                return
            }

            print("We have an error: \(error.localizedDescription)")
        }
    }
    
    private func getUploadPost() -> Post {
        // I want to upload the whole object with the updated votes, because Firebase automatically checks what changed. But I have the loaded User
        let post = Post(type: self.type, title: self.title, createdAt: self.createdAt)
        post.votes = self.votes
        post.language = self.language
        post.report = self.report
        post.commentCount = self.commentCount
        post.anonym = self.anonym
        post.isTopicPost = self.isTopicPost

        return post
    }
}
