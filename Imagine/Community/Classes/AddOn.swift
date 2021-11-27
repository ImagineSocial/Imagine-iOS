//
//  OptionalInformation.swift
//  Imagine
//
//  Created by Malte Schoppe on 02.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

protocol AddOnDelegate {
    func fetchCompleted()
    func itemAdded(successfull: Bool)
}

enum AddOnDesign {
    case normal
    case youTubePlaylist
}

enum AddOnStyle {
    case collection
    case singleTopic
    case QandA
    case collectionWithYTPlaylist
    case playlist
}

class AddOn {
    
    //MARK:- Variables
    var style: AddOnStyle
    var headerTitle: String?
    var description: String
    var documentID: String  // DocumentID of the addOn
    var fact: Community
    var imageURL: String?
    var OP: String
    var design: AddOnDesign = .normal
    var externalLink: String?
    var appleMusicPlaylistURL: String?
    var spotifyPlaylistURL: String?
    
    var singleTopic: Community?
    
    var itemOrder: [String]?    // Order of the items in the addOn by DocumentID
    
    var thanksCount:Int?
    
    let db = Firestore.firestore()
    
    var delegate: AddOnDelegate?
    
    var items = [AddOnItem]()
    
    
    //MARK:- Initialization
    init(style: AddOnStyle, OP: String, documentID: String, fact: Community, headerTitle: String, description: String, singleTopic: Community?) {    /// For the normal AddOn & singleTopic initialization
        self.description = description
        self.headerTitle = headerTitle
        self.documentID = documentID
        self.fact = fact
        self.style = style
        self.OP = OP
        
        if style == .singleTopic {
            if let singleTopic = singleTopic {
                if singleTopic.documentID != "" {
                    let communityRequest = CommunityRequest()

                    communityRequest.getCommunity(language: fact.language, community: singleTopic, beingFollowed: false) { [weak self] (fact) in

                        if let self = self {
                            self.singleTopic = fact
                        }
                    }
                }
            }
        }
    }
    
    init(style: AddOnStyle, OP: String, documentID: String, fact: Community, description: String) {
        self.description = description
        self.documentID = documentID
        self.fact = fact
        self.style = style
        self.OP = OP
    }
    
    
    //MARK:- GetItems
    func getItems(postOnly: Bool) {
        
        if fact.documentID != "" && documentID != "" {
            DispatchQueue.global(qos: .default).async {
                var collectionRef: CollectionReference!
                if self.fact.language == .english {
                    collectionRef = self.db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = self.db.collection("Facts")
                }
                let ref = collectionRef.document(self.fact.documentID).collection("addOns").document(self.documentID).collection("items").order(by: "createDate", descending: true).limit(to: 10)
                
                ref.getDocuments { (snap, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let snap = snap {
                            for document in snap.documents {
                                let data = document.data()
                                guard let type = data["type"] as? String else {
                                    return
                                }
                                if type == "fact" {
                                    
                                    if postOnly {
                                        continue
                                    }
                                    
                                    let fact = Community()
                                    fact.documentID = document.documentID
                                    if let displayOption = data["displayOption"] as? String {
                                        if displayOption == "topic" {
                                            fact.displayOption = .topic
                                        } // else { .fact is default
                                    }
                                    if let title = data["title"] as? String {
                                        fact.addOnTitle = title
                                    }
                                    fact.language = self.fact.language
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: fact)
                                    
                                    self.items.append(item)
                                } else if type == "topicPost" {
                                    let post = Post()
                                    post.documentID = document.documentID
                                    post.isTopicPost = true
                                    post.language = self.fact.language
                                    
                                    if let music = self.addMusicObject(data: data) {
                                        post.music = music
                                    }
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: post)
                                    self.items.append(item)
                                } else {    // Post
                                    let post = Post()
                                    post.documentID = document.documentID
                                    post.language = self.fact.language
                                    
                                    if let postDescription = data["title"] as? String {
                                        post.addOnTitle = postDescription
                                    }
                                    
                                    if let music = self.addMusicObject(data: data) {
                                        post.music = music
                                    }
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: post)
                                    self.items.append(item)
                                }
                            }
                            DispatchQueue.main.async {
                                self.delegate?.fetchCompleted()
                            }
                        }
                    }
                }
            }
        } else {
            print("Not enough info in OptionalInformation getItems")
            return
        }
    }
    
    //MARK:- Set Items
    
    func saveItem(item: Any) {
        
        let itemID: String!
        
        if let fact = item as? Community {
            itemID = fact.documentID
        } else if let post = item as? Post {
            itemID = post.documentID
        } else {
            print("Dont got an item ID")
            return
        }
        
        var collectionRef: CollectionReference!
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(fact.documentID).collection("addOns").document(documentID).collection("items").document(itemID)
        let user = Auth.auth().currentUser!
        
        var data: [String: Any] = ["OP": user.uid, "createDate": Timestamp(date: Date())]
        
        if let fact = item as? Community {
            data["type"] = "fact"

            let newFactVC = NewCommunityItemTableVC()
            let displayOption = newFactVC.getNewFactDisplayString(displayOption: fact.displayOption).displayOption
            data["displayOption"] = displayOption
        } else if let post = item as? Post {

            if let title = post.addOnTitle {    // Description of the added post
                data["title"] = title
            }
            if post.type == .youTubeVideo {
                self.notifyMalteForYouTubePlaylist(fact: fact, addOn: documentID)
            }
            
            if let music = post.music {
                data["musicImage"] = music.musicImageURL
                data["musicName"] = music.name
                data["artist"] = music.artist
                data["musicURL"] = post.linkURL
            }
            
            if post.isTopicPost {
                data["type"] = "topicPost"    // So the getData method looks in a different ref
                self.updateTopicPostInFact(addOnID: documentID, postDocumentID: itemID)
            } else {
                data["type"] = "post"
            }
        }
        
        ref.setData(data) { (err) in
            if let error = err {
                self.delegate?.itemAdded(successfull: false)
                print("We have an error: \(error.localizedDescription)")
            } else {
                var collectionRef: CollectionReference!
                if self.fact.language == .english {
                    collectionRef = self.db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = self.db.collection("Facts")
                }
                
                let docRef = collectionRef.document(self.fact.documentID).collection("addOns").document(self.documentID)
                self.checkIfOrderArrayExists(documentReference: docRef, documentIDOfItem: itemID)
            }
        }
    }
    
    //MARK:- OrderArray
    func checkIfOrderArrayExists(documentReference: DocumentReference, documentIDOfItem: String) {
        documentReference.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let array = data["itemOrder"] as? [String] {
                            self.updateOrderArray(documentReference: documentReference, documentIDOfItem: documentIDOfItem, array: array)
                        } else {
                            self.delegate?.itemAdded(successfull: true)
                            print("No itemOrder yet")
                            return
                        }
                    }
                }
            }
        }
    }
    
    func updateOrderArray(documentReference: DocumentReference, documentIDOfItem: String, array: [String]) {
        var newArray = array
        newArray.insert(documentIDOfItem, at: 0)
        documentReference.updateData([
            "itemOrder": newArray
        ]) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.delegate?.itemAdded(successfull: true)
            }
        }
    }
    
    //MARK:- Database Requests
    
    func updateTopicPostInFact(addOnID: String, postDocumentID: String) {       //Add the AddOnDocumentIDs to the fact, so we can delete every trace of the post if you choose to delete it later. Otherwise there would be empty post in an AddOn
        
        var collectionRef: CollectionReference!
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(fact.documentID).collection("posts").document(postDocumentID)
        
        ref.updateData([
            "addOnDocumentIDs": FieldValue.arrayUnion([addOnID])
        ])
    }
    
    func notifyMalteForYouTubePlaylist(fact: Community, addOn: String) {
        let notificationRef = db.collection("Users").document("CZOcL3VIwMemWwEfutKXGAfdlLy1").collection("notifications").document()
        let language = Locale.preferredLanguages[0]
        let notificationData: [String: Any] = ["type": "message", "message": "Wir haben einen neuen YouTubePost in \(fact.title) mit der ID: \(addOn)", "name": "System", "chatID": addOn, "sentAt": Timestamp(date: Date()), "messageID": "Dont Know", "language": language]
        
        
        notificationRef.setData(notificationData) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully set notification")
            }
        }
    }
    
    //MARK:- AddMusicObject
    
    func addMusicObject(data: [String:Any]) -> Music? {
        if let image = data["musicImage"] as? String,
           let name = data["musicName"] as? String,
           let artist = data["artist"] as? String,
           let url = data["musicURL"] as? String {
            let music = Music(type: .track, name: name, artist: artist, musicImageURL: image, songwhipURL: url)
            
            return music
        } else {
            return nil
        }
    }
}

