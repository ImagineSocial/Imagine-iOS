//
//  Post.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore

struct PostDesignOption {
    var hideProfilePicture = false
}

class Post {
    
    //MARK:- Variables
    var title = ""
    var imageURL = ""
    var imageURLs: [String]?
    var description = ""
    var linkURL = ""
    var link: Link?
    var music: Music?
    var type: PostType = .picture
    var mediaHeight: CGFloat = 0.0
    var mediaWidth: CGFloat = 0.0
    var report:ReportType = .normal
    var documentID = ""
    var createTime = ""
    var repostDocumentID: String?
    var repostIsTopicPost = false
    var repostLanguage: Language = .german
    var originalPosterUID = ""      // kann eigentlich weg weil in User Objekt
    var commentCount = 0
    var createDate: Date?
    var toComments = false // If you want to skip to comments (For now)
    var anonym = false
    var anonymousName: String?
    var user = User()
    var votes = Votes()
    var newUpvotes: Votes?
    var repost: Post?
    var fact:Community?
    var addOnTitle: String?    // Description in the OptionalInformation Section in the topic area
    var isTopicPost = false // Just postet in a topic, not in the main feed
    var language: Language = .german
    var designOptions: PostDesignOption?
    var location: Location?
    
    var notificationRecipients = [String]()
    
    var survey: Survey?
    
    let handyHelper = HandyHelper()
    let db = Firestore.firestore()
    
    
    //MARK: Get Repost
    func getRepost(returnRepost: @escaping (Post) -> Void) {
        if let repostID = repostDocumentID {
            var collectionRef: CollectionReference!
            if repostIsTopicPost {
                if repostLanguage == .english {
                    collectionRef = db.collection("Data").document("en").collection("topicPosts")
                } else {
                    collectionRef = db.collection("TopicPosts")
                }
            } else {
                if repostLanguage == .english {
                    collectionRef = db.collection("Data").document("en").collection("posts")
                } else {
                    collectionRef = db.collection("Posts")
                }
            }
    
            let postRef = collectionRef.document(repostID)
                        
            postRef.getDocument(completion: { (document, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else if let document = document {
                    let postHelper = PostHelper()
                    
                    if let post = postHelper.addThePost(document: document, isTopicPost: self.repostIsTopicPost, language: self.repostLanguage) {
                        
                        returnRepost(post)
                    }
                }
            })
        }
    }
    
    //MARK:- Get User
    //TODO: Makes no Sense here, should go into User class
    func getUser(isAFriend: Bool) {
        
        // User Daten raussuchen
        let userRef = db.collection("Users").document(originalPosterUID)
        
        let user = User()
        
        userRef.getDocument(completion: { (document, err) in
            if let error = err {
                print("We got an error with a user: \(error.localizedDescription)")
            } else {
                if let document = document {
                    if let docData = document.data() {
                        
                        if isAFriend {
                            let fullName = docData["full_name"] as? String ?? ""
                            user.displayName = fullName
                        } else {
                            let userName = docData["name"] as? String ?? "Username"
                            user.displayName = userName
                        }
                        
                        if let instagramLink = docData["instagramLink"] as? String {
                            user.instagramLink = instagramLink
                            user.instagramDescription = docData["instagramDescription"] as? String
                        }
                        
                        if let patreonLink = docData["patreonLink"] as? String {
                            user.patreonLink = patreonLink
                            user.patreonDescription = docData["patreonDescription"] as? String
                        }
                        if let youTubeLink = docData["youTubeLink"] as? String {
                            user.youTubeLink = youTubeLink
                            user.youTubeDescription = docData["youTubeDescription"] as? String
                        }
                        if let twitterLink = docData["twitterLink"] as? String {
                            user.twitterLink = twitterLink
                            user.twitterDescription = docData["twitterDescription"] as? String
                        }
                        if let songwhipLink = docData["songwhipLink"] as? String {
                            user.songwhipLink = songwhipLink
                            user.songwhipDescription = docData["songwhipDescription"] as? String
                        }
                        
                        if let locationName = docData["locationName"] as? String {
                            user.locationName = locationName
                        }
                        if let locationIsPublic = docData["locationIsPublic"] as? Bool {
                            user.locationIsPublic = locationIsPublic
                        }
                        
                        user.imageURL = docData["profilePictureURL"] as? String ?? ""
                        user.userUID = self.originalPosterUID
                        user.statusQuote = docData["statusText"] as? String ?? ""
                        user.blocked = docData["blocked"] as? [String] ?? nil
                        
                        self.user = user
                    }
                }
            }
        })
    }
}
