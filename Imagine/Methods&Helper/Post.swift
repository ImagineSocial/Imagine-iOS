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

// This enum declares the type of the post
enum PostType {
    case picture
    case link
    case thought
    case repost
    case event
    case youTubeVideo
    case nothingPostedYet
}

// This enum declares how a post was marked or reported
enum ReportType {
    case normal
    case spoiler
    case opinion
    case sensationalism
    case circlejerk
    case pretentious
    case edited
    case ignorant
}

class Post {
    var title = ""
    var imageURL = ""
    var description = ""
    var linkURL = ""
    var type: PostType = .picture
    var imageHeight: CGFloat = 0.0
    var imageWidth: CGFloat = 0.0
    var report:ReportType = .normal
    var documentID = ""
    var createTime = ""
    var OGRepostDocumentID: String?
    var originalPosterUID = ""      // kann eigentlich weg weil in User Objekt
    var commentCount = 0
    var createDate: Date?
    var user = User()
    var votes = Votes()
    var event = Event()
    var repost: Post?
    
    let handyHelper = HandyHelper()
    
    
    func getRepost(returnRepost: @escaping (Post) -> Void) {
        let db = Firestore.firestore()
        if let repostID = OGRepostDocumentID {
            let postRef = db.collection("Posts").document(repostID)
            
            let post = Post()
            
            postRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        guard let title = docData["title"] as? String,
                            let description = docData["description"] as? String,
                            let report = docData["report"] as? String,
                            let createTimestamp = docData["createTime"] as? Timestamp,
                            let originalPoster = docData["originalPoster"] as? String,
                            let thanksCount = docData["thanksCount"] as? Int,
                            let wowCount = docData["wowCount"] as? Int,
                            let haCount = docData["haCount"] as? Int,
                            let niceCount = docData["niceCount"] as? Int,
                            let postType = docData["type"] as? String
                            
                            else {
                                return
                        }
                        
                        let linkURL = docData["link"] as? String ?? ""
                        let imageURL = docData["imageURL"] as? String ?? ""
                        let picHeight = docData["imageHeight"] as? Double ?? 0
                        let picWidth = docData["imageWidth"] as? Double ?? 0
                        
                        let stringDate = createTimestamp.dateValue().formatRelativeString()
                        
                        post.title = title      // Sachen zuordnen
                        post.imageURL = imageURL
                        post.imageHeight = CGFloat(picHeight)
                        post.imageWidth = CGFloat(picWidth)
                        post.description = description
                        post.documentID = document.documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        post.linkURL = linkURL
                        
                        if let reportType = self.handyHelper.setReportType(fetchedString: report) {
                            post.report = reportType
                        }
                        
                        if let postType = self.handyHelper.setPostType(fetchedString: postType) {
                            post.type = postType
                        }
                        
                        post.getUser()
                            
                        returnRepost(post)
                    }
                }
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "")")
                }
            })
        }
    }
    
    func getUser() {
        
        let db = Firestore.firestore()
        // User Daten raussuchen
        let userRef = db.collection("Users").document(originalPosterUID)
        
        let user = User()
        
        userRef.getDocument(completion: { (document, err) in
            if let document = document {
                if let docData = document.data() {
                    
                    user.name = docData["name"] as? String ?? ""
                    user.surname = docData["surname"] as? String ?? ""
                    user.imageURL = docData["profilePictureURL"] as? String ?? ""
                    user.userUID = self.originalPosterUID
                    user.statusQuote = docData["statusText"] as? String ?? ""
                    user.blocked = docData["blocked"] as? [String] ?? nil
                    
                    self.user = user
                }
            }
            
            if err != nil {
                print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "")")
            }
        })
    }
}



public class User {
    public var name = ""
    public var surname = ""
    public var imageURL = ""
    public var userUID = ""
    public var image = UIImage(named: "default-user")
    public var blocked: [String]?
    public var statusQuote = ""
}
