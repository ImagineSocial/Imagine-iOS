//
//  PostHelper.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import SDWebImage

public var lastSnap: QueryDocumentSnapshot?     // public for the next fetch cycle, I think it is unnötig, because i solved it by keeping just one instance of posthelper instead of initiating it over and over again, that is why the posts stay the same and so on
public var lastEventSnap: QueryDocumentSnapshot?

enum PostType {
    case picture
    case link
    case thought
    case repost
    case event
    case youTubeVideo
}

class PostHelper {
    
    var posts = [Post]()
    let db = Firestore.firestore()
    
    func getPosts(getMore:Bool, returnPosts: @escaping ([Post]) -> Void) {
        
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        var postRef = db.collection("Posts").order(by: "createTime", descending: true).limit(to: 20)
        
        if getMore {    // If you want to get More Posts
            if let lastSnap = lastSnap {        // For the next loading batch of 20, that will start after this snapshot
                postRef = postRef.start(afterDocument: lastSnap)
            }
        } else { // Else you want to refresh the feed
            self.posts.removeAll()
        }
        
        postRef.getDocuments { (querySnapshot, error) in
            
            lastSnap = querySnapshot?.documents.last    // Last document for the next fetch cycle
            
            for document in querySnapshot!.documents {
                
                
                let documentID = document.documentID
                let documentData = document.data()
                
                
                if let postType = documentData["type"] as? String {
                    
                    // Werte die alle haben
                    guard let title = documentData["title"] as? String,
                        let description = documentData["description"] as? String,
                        let report = documentData["report"] as? String,
                        let createTimestamp = documentData["createTime"] as? Timestamp,
                        let originalPoster = documentData["originalPoster"] as? String,
                        let thanksCount = documentData["thanksCount"] as? Int,
                        let wowCount = documentData["wowCount"] as? Int,
                        let haCount = documentData["haCount"] as? Int,
                        let niceCount = documentData["niceCount"] as? Int
                        
                        else {
                            continue    // Falls er das nicht als (String) zuordnen kann
                    }
                    
                    let stringDate = HandyHelper().getStringDate(timestamp: createTimestamp)
                    
                    // Thought
                    if postType == "thought" {
                            
                        
                        let post = Post()       // Erst neuen Post erstellen
                        post.title = title      // Dann die Sachen zuordnen
                        post.description = description
                        post.type = .thought
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                    
                        
                
                        self.posts.append(post)
                      
                        
                    // Picture
                    } else if postType == "picture" {
                        
                        guard let imageURL = documentData["imageURL"] as? String,
                        let picHeight = documentData["imageHeight"] as? Double,
                        let picWidth = documentData["imageWidth"] as? Double
                       
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let post = Post()       // Erst neuen Post erstellen
                        post.title = title      // Dann die Sachen zuordnen
                        post.imageURL = imageURL
                        post.imageHeight = CGFloat(picHeight)
                        post.imageWidth = CGFloat(picWidth)
                        post.description = description
                        post.type = .picture
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        
                        self.posts.append(post)
                    
                    // YouTubeVideo
                    } else if postType == "youTubeVideo" {
                        
                        guard let linkURL = documentData["link"] as? String else { continue }
                        
                        let post = Post()
                        post.title = title
                        post.linkURL = linkURL
                        post.description = description
                        post.type = .youTubeVideo
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        
                        
                        self.posts.append(post)
                        
                      //Link
                    } else if postType == "link" {
                        
                        guard let linkURL = documentData["link"] as? String
                            
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let post = Post()       // Erst neuen Post erstellen
                        post.title = title      // Dann die Sachen zuordnen
                        post.linkURL = linkURL
                        post.description = description
                        post.type = .link
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount

                        
                        self.posts.append(post)
                        
                        // Repost
                    } else if postType == "repost" || postType == "translation" {
                        
                        guard let postDocumentID = documentData["OGpostDocumentID"] as? String
                            
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let post = Post()
                        post.type = .repost
                        post.title = title
                        post.report = report
                        post.description = description
                        post.createTime = stringDate
                        post.OGRepostDocumentID = postDocumentID
                        post.documentID = documentID
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        
                        post.getRepost(returnRepost: { (repost) in
                            post.repost = repost
                        })
                        
                        self.posts.append(post)
                        
                    }
                }
            }
            self.getCommentCount(post: self.posts, completion: {})
            
            self.getUsers(postList: self.posts, completion: { (postsWithUser) in
                
                    returnPosts(postsWithUser)
                
            })
            
            
        }
    }
    
    func getEvent(completion: @escaping (Post) -> Void) {
        
        var eventRef = db.collection("Events").limit(to: 1)
        
        if let lastEventSnap = lastEventSnap {        // For the next loading batch of 20, there will be one event
            eventRef = eventRef.start(afterDocument: lastEventSnap)
        }
        
        eventRef.getDocuments { (eventSnap, err) in
            if let err = err {
                print("Wir haben einen Error beim Event: \(err.localizedDescription)")
            }
            
            for event in eventSnap!.documents {
                
                let documentID = event.documentID
                let documentData = event.data()
                
                guard let title = documentData["title"] as? String,
                let description = documentData["description"] as? String,
                let location = documentData["location"] as? String,
                let type = documentData["type"] as? String,
                let imageURL = documentData["imageURL"] as? String,
                let imageHeight = documentData["imageHeight"] as? CGFloat,
                let imageWidth = documentData["imageWidth"] as? CGFloat,
                let participants = documentData["participants"] as? [String],
                let admin = documentData["admin"] as? String,
                let createDate = documentData["createDate"] as? Timestamp
                
                else {
                    continue
                }
                
                let stringDate = HandyHelper().getStringDate(timestamp: createDate)
                
                let post = Post()
                let event = Event()
            
                event.title = title
                event.description = description
                event.location = location
                event.type = type
                event.imageURL = imageURL
                event.imageWidth = imageWidth
                event.imageHeight = imageHeight
                event.participants = participants
                event.createDate = stringDate
                
                post.originalPosterUID = admin
                post.documentID = documentID
                post.type = .event
                
                post.event = event
                
                completion(post)
                
            }
            
        }
        
    }
    
    func getUsers(postList: [Post], completion: @escaping ([Post]) -> Void) {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        for post in postList {
            // Vorläufig Daten hinzufügen
//              print("postID::::::" , post.documentID)
//            if post.type == "repost" || post.type == "translation" {
//                let postRef = db.collection("Posts").document(post.documentID)
//                let documentData : [String:Any] = ["thanksCount": 8, "wowCount": 4, "haCount": 3, "niceCount": 2]
//
//                postRef.setData(documentData, merge: true)
//            }
            
            
            // User Daten raussuchen
            let userRef = db.collection("Users").document(post.originalPosterUID)
            
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        let user = User()
                        
                        user.name = docData["name"] as? String ?? ""
                        user.surname = docData["surname"] as? String ?? ""
                        user.imageURL = docData["profilePictureURL"] as? String ?? ""
                        user.userUID = post.originalPosterUID
                        
                        post.user = user
                    }
                }
                
                if let err = err {
                    print("Wir haben einen Error beim User: \(err.localizedDescription)")
                }
            })
            
        }
//        DispatchQueue.main.async {
            completion(postList)
//        }
        
    }
    
    
    func getCommentCount(post: [Post], completion: () -> Void) {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        
        for post in posts {
            // Comment Count raussuchen wenn Post
            
            if post.type != .event { // Wenn kein Event
                
            let commentRef = db.collection("Comments").document(post.documentID).collection("threads")
            
            commentRef.getDocuments { (snapshot, err) in
                if let err = err {
                    print("Wir haben einen Error beim User: \(err.localizedDescription)")
                }
                if let snapshot = snapshot {
                    let number = snapshot.count
                    post.commentCount = number
                }
            }
        }
        }
        
        completion()
    }
    
    
    
    
    
    func getChatUser(uid: String, sender: Bool, user: @escaping (ChatUser) -> Void) {
        
        let userRef = db.collection("Users").document(uid)
        
        var chatUser : ChatUser?
        
        userRef.getDocument(completion: { (document, err) in
            if let document = document {
                if let docData = document.data() {
                    
                    guard let name = docData["name"] as? String,
                        let surname = docData["surname"] as? String,
                        let imageURL = docData["profilePictureURL"] as? String
                        else {
                            return
                    }
                    
                    // Hier Avatar als UIImage einführen
                    
                    if let url = URL(string: imageURL) {
                        let defchatUser = ChatUser(displayName: "\(name) \(surname)", avatar: nil, avatarURL: url, isSender: sender)
                        
//                        let imageView = UIImageView()
//                        var image = UIImage()
//                        imageView.sd_setImage(with: url, completed: { (newImage, _, _, _) in
//                        
//                        })
//                        if let data = try? Data(contentsOf: url) {
//                            let image:UIImage = UIImage.sd_image(with: data)
//                        }
                        
                        chatUser = defchatUser
                    } else {
                        
                        let defchatUser = ChatUser(displayName: "\(name) \(surname)", avatar: nil, avatarURL: nil, isSender: sender)
                        chatUser = defchatUser
                    }
                }
            }
            if let err = err {
                print("Wir haben einen Error beim User: \(err.localizedDescription)")
            }
            
            if let daChatUser = chatUser{
                user(daChatUser)
            }
        })
    }
}





class Votes {
    var thanks = 0
    var wow = 0
    var ha = 0
    var nice = 0
}

class ReportOptions {
    // Optisch Markieren
    let opticOptionArray = ["Spoiler", "Meinung, kein Fakt", "Sensationalismus", "Circlejerk", "Angeberisch", "Bildbearbeitung", "Schwarz-Weiß-Denken"]
    // Schlechte Absichten
    let badIntentionArray = ["Hass gegen ...","Respektlos", "Beleidigend", "(sexuell) Belästigend", "Rassistisch", "Homophob", "Gewaltunterstüztend", "Verharmlosung von Suizid", "Glauben nicht respektieren"]
    // Lüge/Täuschung
    let lieDeceptionArray = ["Fake News","Beweise verneinen", "Verschwörungstheorie"]
    // Inhalt
    let contentArray = ["Pornografie","Pedophilie", "Gewaltdarstellung", "Vorurteil"]
}
