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

class PostHelper {
    
    var posts = [Post]()
    let db = Firestore.firestore()
    
    func getPosts(returnPosts: @escaping ([Post]) -> Void) {
        
    
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        let postRef = db.collection("Posts").order(by: "createTime", descending: true)  
        postRef.getDocuments { (querySnapshot, error) in
            
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
                    
                    let poster = self.getUser(userUID: originalPoster)
                    
                    
//                    self.getUser(userUID: originalPoster, completion: { (fetchedUser) in
//                        poster = fetchedUser
//                    })
                    
                    // Thought
                    if postType == "thought" {
                        
                        
                        guard let description = documentData["description"] as? String,
                        let report = documentData["report"] as? String
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let post = Post()       // Erst neuen Post erstellen
                        post.title = title      // Dann die Sachen zuordnen
                        post.description = description
                        post.type = postType
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        post.user = poster
                    
                        
                
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
                        post.type = postType
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        post.user = poster
                        
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
                        post.type = postType
                        post.report = report
                        post.documentID = documentID
                        post.createTime = stringDate
                        post.originalPosterUID = originalPoster
                        post.votes.thanks = thanksCount
                        post.votes.wow = wowCount
                        post.votes.ha = haCount
                        post.votes.nice = niceCount
                        post.user = poster

                        
                        self.posts.append(post)
                        
                        // Repost
                    } else if postType == "repost" || postType == "translation" {
                        
                        guard let postDocumentID = documentData["OGpostDocumentID"] as? String
                            
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let post = Post()
                        post.type = postType
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
                        post.user = poster
                        
                        
                        self.posts.append(post)
                        
                    }
                }
            }
            self.getCommentCount(post: self.posts, completion: {
            })
            returnPosts(self.posts)
            
//            self.getUsers(postList: self.posts, completion: { (posts) in
//
//
//                    print("Return Posts")
//                    returnPosts(posts)
//
//            })
            
        }
    }
    
    func getUsers(postList: [Post], completion: ([Post]) -> Void) {
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
                
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription)")
                }
            })
            
        }
            completion(postList)
            print("Return User")
    }
    
    func getUser(userUID: String) -> User {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        
            // User Daten raussuchen
            let userRef = db.collection("Users").document(userUID)
        
            let user = User()
        
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        user.name = docData["name"] as? String ?? ""
                        user.surname = docData["surname"] as? String ?? ""
                        user.imageURL = docData["profilePictureURL"] as? String ?? ""
                        user.userUID = userUID
                        
                    }
                }
                
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription)")
                }
            })
        
        print("Der User wird returned: \(user.userUID)")
            return user
        }
    
    func getCommentCount(post: [Post], completion: () -> Void) {
        //Wenn die Funktion fertig ist soll returnPosts bei der anderen losgehen
        
        for post in posts {
            // User Daten raussuchen
            let commentRef = db.collection("Comments").document(post.documentID).collection("threads")
            
            commentRef.getDocuments { (snapshot, err) in
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription)")
                }
                if let snapshot = snapshot {
                    let number = snapshot.count
                    post.commentCount = number
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
            if err != nil {
                print("Wir haben einen Error beim User: \(err?.localizedDescription)")
            }
            
            if let daChatUser = chatUser{
                user(daChatUser)
            }
        })
    }
}

class Post {
    var title = ""
    var imageURL = ""
    var description = ""
    var linkURL = ""
    var type = ""
    var imageHeight: CGFloat = 0.0
    var imageWidth: CGFloat = 0.0
    var report = ""
    var documentID = ""
    var createTime = ""
    var OGRepostDocumentID = ""
    var originalPosterUID = ""
    var commentCount = 0
    var user = User()
    var votes = Votes()
}

class User {
    var name = ""
    var surname = ""
    var imageURL = ""
    var userUID = ""
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
