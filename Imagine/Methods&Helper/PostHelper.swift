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

class PostHelper {
    
    func getPosts(returnPosts: @escaping ([Post]) -> Void) {
        
    let db = Firestore.firestore()
        let settings = db.settings
        settings.areTimestampsInSnapshotsEnabled = true
        db.settings = settings
        
        
        var posts = [Post]()
        var name = ""
        var surname = ""
        var profilePictureURL = ""
        
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
                        let originalPoster = documentData["originalPoster"] as? String
                        
                    
                        
                        else {
                            continue    // Falls er das nicht als (String) zuordnen kann
                    }
                    
                    // Timestamp umwandeln
                    let formatter = DateFormatter()
                    let date:Date = createTimestamp.dateValue()
                    formatter.dateFormat = "dd MM yyyy HH:mm"
                    let stringDate = formatter.string(from: date)
                    
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
                
                        posts.append(post)
                      
                        
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
                        
                        posts.append(post)
                    
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

                        
                        posts.append(post)
                        
                        // Repost
                    } else if postType == "repost" {
                        
                        guard let postDocumentID = documentData["OGpostDocumentID"] as? String
                            
                            else {
                                continue    // Falls er das nicht als (String) zuordnen kann
                        }
                        
                        let post = Post()       // Erst neuen Post erstellen
                        post.type = postType
                        post.title = title
                        post.description = description
                        post.createTime = stringDate
                        post.OGRepostDocumentID = postDocumentID     // Dann die Sachen zuordnen
                        post.originalPosterUID = originalPoster
                        
                        posts.append(post)
                        
                    }
                }
            }
            
            for post in posts {
                // User Daten raussuchen
                let userRef = db.collection("Users").document(post.originalPosterUID)
                
                userRef.getDocument(completion: { (document, err) in
                    if let document = document {
                        if let docData = document.data() {
                            
                            name = docData["name"] as? String ?? ""
                            surname = docData["surname"] as? String ?? ""
                            profilePictureURL = docData["profilePictureURL"] as? String ?? ""
                            
                            post.originalPosterName = "\(name) \(surname)"
                            post.originalPosterImageURL = profilePictureURL
                            
                        }
                    }
                    
                    if err != nil {
                        print("Wir haben einen Error beim User: \(err?.localizedDescription)")
                    }
                })
            }
            
            returnPosts(posts)
        }
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
    var originalPosterName = ""
    var originalPosterImageURL = ""
    var originalPosterUID = ""
}

class ReportOptions {
    // Optisch Markieren
    let opticOptionArray = ["Meinung, kein Fakt", "Sensationalismus", "Circlejerk", "Angeberisch", "Bildbearbeitung", "Schwarz-Weiß-Denken"]
    // Schlechte Absichten
    let badIntentionArray = ["Hass gegen ...","Respektlos", "Beleidigend", "(sexuell) Belästigend", "Rassistisch", "Homophob", "Gewaltunterstüztend", "Verharmlosung von Suizid", "Glauben nicht respektieren"]
    // Lüge/Täuschung
    let lieDeceptionArray = ["Fake News","Beweise verneinen", "Verschwörungstheorie"]
    // Inhalt
    let contentArray = ["Pornografie","Pedophilie", "Gewaltdarstellung", "Vorurteil"]
}
