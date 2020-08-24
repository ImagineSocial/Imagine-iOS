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
    case GIF
    case multiPicture
    case topTopicCell
    case nothingPostedYet
}

// This enum declares how a post was marked or reported
enum ReportType {
    case normal
    case spoiler
    case satire
    case opinion
    case sensationalism
    case circlejerk
    case pretentious
    case edited
    case ignorant
    case misinformation
    case misleading
}

class Votes {
    var thanks = 0
    var wow = 0
    var ha = 0
    var nice = 0
}

class Post {
    var title = ""
    var imageURL = ""
    var imageURLs: [String]?
    var description = ""
    var linkURL = ""
    var type: PostType = .picture
    var mediaHeight: CGFloat = 0.0
    var mediaWidth: CGFloat = 0.0
    var report:ReportType = .normal
    var documentID = ""
    var createTime = ""
    var OGRepostDocumentID: String?
    var originalPosterUID = ""      // kann eigentlich weg weil in User Objekt
    var commentCount = 0
    var createDate: Date?
    var toComments = false // If you want to skip to comments (For now)
    var anonym = false
    var anonymousName: String?
    var user = User()
    var votes = Votes()
    var event = Event()
    var repost: Post?
    var fact:Fact?
    var addOnTitle: String?    // Description in the OptionalInformation Section in the topic area
    var isTopicPost = false // Just postet in a topic, not in the main feed
    
    var notificationRecipients = [String]()
    
    var survey: Survey?
    
    let handyHelper = HandyHelper()
    let db = Firestore.firestore()
    
    
    func getRepost(returnRepost: @escaping (Post) -> Void) {
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
                        post.mediaHeight = CGFloat(picHeight)
                        post.mediaWidth = CGFloat(picWidth)
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
                        
                        if let factID = docData["linkedFactID"] as? String {
                            let fact = Fact()
                            fact.documentID = factID
                            
                            post.fact = fact
                        }
                        
                        if let postType = self.handyHelper.setPostType(fetchedString: postType) {
                            post.type = postType
                        }
                        
                        if originalPoster == "anonym" {
                            post.anonym = true
                        } else {
                            post.getUser(isAFriend: false)
                        }
                            
                        returnRepost(post)
                    }
                }
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription ?? "")")
                }
            })
        }
    }
    
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
                        }
                        if let patreonLink = docData["patreonLink"] as? String {
                            user.patreonLink = patreonLink
                        }
                        if let youTubeLink = docData["youTubeLink"] as? String {
                            user.youTubeLink = youTubeLink
                        }
                        if let twitterLink = docData["twitterLink"] as? String {
                            user.twitterLink = twitterLink
                        }
                        if let songwhipLink = docData["songwhipLink"] as? String {
                            user.songwhipLink = songwhipLink
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
    
    func getCommentCount() {
        
        if self.documentID != "" {
            let commentRef = db.collection("Comments").document(self.documentID).collection("threads")
            
            commentRef.getDocuments { (snap, err) in
                if let err = err {
                    print("Wir haben einen Error beim User: \(err.localizedDescription)")
                }
                if let snapshot = snap {
                    self.commentCount = snapshot.count
                }
            }
        }
    }
}



public class User {
    public var displayName = ""
    public var imageURL = ""
    public var userUID = ""
    public var image = UIImage(named: "default-user")
    public var blocked: [String]?
    public var statusQuote = ""
    
    //Social Media Links
    public var instagramLink: String?
    public var patreonLink: String?
    public var youTubeLink: String?
    public var twitterLink: String?
    public var songwhipLink: String?
    
    //location
    public var locationName: String?
    public var locationIsPublic = false
    
    let db = Firestore.firestore()
    
    func getBadges(returnBadges: @escaping ([String]) -> Void) {
        
        if userUID != "" {
            let ref = db.collection("Users").document(userUID)
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let data = snap.data() {
                            if let badges = data["badges"] as? [String] {
                                returnBadges(badges)
                            }
                        }
                    }
                }
            }
        } else {
            print("Got no UID for badges")
        }
    }
}
