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

protocol OptionalInformationDelegate {
    func fetchCompleted()
}

enum OptionalInformationStyle {
    case collection
    case singleTopic
    case QandA
}

class AddOnItem {   // Otherwise it is a pain in the ass to compare Any to the documentIDs in the itemOrder Array
    var documentID: String
    var item: Any
    
    init(documentID: String, item: Any) {
        self.documentID = documentID
        self.item = item
    }
}

class OptionalInformation {
    
    var style: OptionalInformationStyle
    var headerTitle: String?
    var description: String
    var documentID: String  // DocumentID of the addOn
    var fact: Fact
    var imageURL: String?
    var OP: String
    
    var singleTopic: Fact?
    
    var itemOrder: [String]?    // Order of the items in the addOn by DocumentID
    
    var thanksCount:Int?
    
    let db = Firestore.firestore()
    
    var delegate: OptionalInformationDelegate?
    
    var items = [AddOnItem]()
    
    init(style: OptionalInformationStyle, OP: String, documentID: String, fact: Fact, headerTitle: String, description: String, singleTopic: Fact?) {    /// For the normal AddOn & singleTopic initialization
        self.description = description
        self.headerTitle = headerTitle
        self.documentID = documentID
        self.fact = fact
        self.style = style
        self.OP = OP
        
        if style == .singleTopic {
            if let singleTopic = singleTopic {
                self.singleTopic = singleTopic
                if singleTopic.documentID != "" {
                    let baseFeedCell = BaseFeedCell()
                    DispatchQueue.global(qos: .default).async {
                        baseFeedCell.loadFact(language: fact.language, fact: singleTopic, beingFollowed: false) { (fact) in
                            self.singleTopic = fact
                        }
                    }
                }
            }
        }
    }
    
    init(style: OptionalInformationStyle, OP: String, documentID: String, fact: Fact, description: String) {
        self.description = description
        self.documentID = documentID
        self.fact = fact
        self.style = style
        self.OP = OP
    }
    
    func getDisplayOptions() {
        //        if let displayType = data["displayOption"] as? String { // Was introduced later on
        //            fact.displayOption = self.getDisplayType(string: displayType)
        //        }
        //
        //        if let displayNames = data["factDisplayNames"] as? String {
        //            fact.factDisplayNames = self.getDisplayNames(string: displayNames)
        //        }
    }
    
    func getItems() {
        
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
                                    let fact = Fact()
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
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: post)
                                    self.items.append(item)
                                } else {    // Post
                                    let post = Post()
                                    post.documentID = document.documentID
                                    post.language = self.fact.language
                                    
                                    if let postDescription = data["title"] as? String {
                                        post.addOnTitle = postDescription
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
}

