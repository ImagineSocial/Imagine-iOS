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
    var music: Music?
    var report = ReportType.normal
    var repostDocumentID: String?
    var repostIsTopicPost = false
    var repostLanguage = Language.de
    var commentCount = 0
    var toComments = false // If you want to skip to comments (For now)
    var anonym = false
    var user: User?
    var userID: String?
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
    var notificationRecipients = [String]()
    
    var survey: Survey?
    
    var community: Community?
    
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
    
    func getRepost(returnRepost: @escaping (Post) -> Void) {
        
        let db = FirestoreRequest.shared.db
        
        if let repostID = repostDocumentID {
            var collectionRef: CollectionReference!
            if repostIsTopicPost {
                if repostLanguage == .en {
                    collectionRef = db.collection("Data").document("en").collection("topicPosts")
                } else {
                    collectionRef = db.collection("TopicPosts")
                }
            } else {
                if repostLanguage == .en {
                    collectionRef = db.collection("Data").document("en").collection("posts")
                } else {
                    collectionRef = db.collection("Posts")
                }
            }
    
            let postRef = collectionRef.document(repostID)
                        
            postRef.getDocument(completion: { [weak self] (document, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else if let document = document {
                    if let post = PostHelper.shared.addThePost(document: document, isTopicPost: self!.repostIsTopicPost, language: self!.repostLanguage) {
                        
                        returnRepost(post)
                    }
                }
            })
        }
    }
}
