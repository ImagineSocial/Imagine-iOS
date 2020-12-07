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
    case translation
    case event
    case youTubeVideo
    case GIF
    case multiPicture
    case singleTopic
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

enum MusicType {
    case track
    case album
}

class Music {
    var type: MusicType
    var name: String
    var artist: String
    var releaseDate: Date?
    var artistImageURL: String?
    var musicImageURL: String
    var songwhipURL: String
    
    ///Playlist init
    init(type:MusicType, name: String, artist: String, musicImageURL: String, songwhipURL: String) {
        self.type = type
        self.name = name
        self.artist = artist
        self.musicImageURL = musicImageURL
        self.songwhipURL = songwhipURL
    }
    
    init(type: MusicType, name: String, artist: String, releaseDate: Date, artistImageURL: String, musicImageURL: String, songwhipURL: String) {
        self.type = type
        self.name = name
        self.artist = artist
        self.releaseDate = releaseDate
        self.artistImageURL = artistImageURL
        self.musicImageURL = musicImageURL
        self.songwhipURL = songwhipURL
    }
}

class Link {
    var imageURL: String?
    var link: String
    var shortURL: String
    var linkTitle: String
    var linkDescription: String
    
    init(link: String, title: String, description: String, shortURL: String, imageURL: String?) {
        self.link = link
        self.linkTitle = title
        self.linkDescription = description
        self.shortURL = shortURL
        self.imageURL = imageURL
    }
}

class Post {
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
    var event = Event()
    var repost: Post?
    var fact:Fact?
    var addOnTitle: String?    // Description in the OptionalInformation Section in the topic area
    var isTopicPost = false // Just postet in a topic, not in the main feed
    var language: Language = .german
    
    var notificationRecipients = [String]()
    
    var survey: Survey?
    
    let handyHelper = HandyHelper()
    let db = Firestore.firestore()
    
    
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
                    
                    if let post = postHelper.addThePost(document: document, isTopicPost: self.repostIsTopicPost, forFeed: false, language: self.repostLanguage) {
                        
                        returnRepost(post)
                    }
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
    
//    func getCommentCount() {
//
//        if self.documentID != "" {
//            let commentRef = db.collection("Comments").document(self.documentID).collection("threads")
//
//            commentRef.getDocuments { (snap, err) in
//                if let err = err {
//                    print("Wir haben einen Error beim User: \(err.localizedDescription)")
//                }
//                if let snapshot = snap {
//                    self.commentCount = snapshot.count
//                }
//            }
//        }
//    }
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
    public var instagramDescription: String?
    public var patreonLink: String?
    public var patreonDescription: String?
    public var youTubeLink: String?
    public var youTubeDescription: String?
    public var twitterLink: String?
    public var twitterDescription: String?
    public var songwhipLink: String?
    public var songwhipDescription: String?
    
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
