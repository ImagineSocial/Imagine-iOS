//
//  Post.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import FirebaseFirestore

struct PostDesignOption: Codable {
    var hideProfilePicture = false
}

class Post: Codable {
    
    //MARK:- Variables
    var title = ""
    var imageURL = ""
    var imageURLs: [String]?
    var thumbnailImageURL: String?
    var description = ""
    var linkURL = ""
    var link: Link?
    var music: Music?
    var type: PostType = .picture
    var mediaHeight: CGFloat = 0.0
    var mediaWidth: CGFloat = 0.0
    var report: ReportType = .normal
    var documentID = ""
    var createTime = ""
    var repostDocumentID: String?
    var repostIsTopicPost = false
    var repostLanguage: Language = .de
    var commentCount = 0
    var createDate: Date?
    var toComments = false // If you want to skip to comments (For now)
    var anonym = false
    var anonymousName: String?
    var user: User?
    var votes = Votes()
    var newUpvotes: Votes?
    var repost: Post?
    var community: Community?
    var addOnTitle: String?    // Description in the OptionalInformation Section in the topic area
    var isTopicPost = false // Just postet in a topic, not in the main feed
    var language: Language = .de
    var designOptions: PostDesignOption?
    var location: Location?
    
    var notificationRecipients = [String]()
    
    var survey: Survey?
    
    
    //MARK: Get Repost
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
