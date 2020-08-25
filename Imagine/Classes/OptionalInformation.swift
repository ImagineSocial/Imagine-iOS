//
//  OptionalInformation.swift
//  Imagine
//
//  Created by Malte Schoppe on 02.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol OptionalInformationDelegate {
    func done()
}

enum OptionalInformationStyle {
    case justPosts
    case justTopics
    case all
    case header
    case singleTopic
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
    var addOnInfoHeader: AddOnInfoHeader?
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
                    self.getFact(documentID: singleTopic.documentID)
                }
            }
        }
    }
    
    init(style: OptionalInformationStyle, OP: String, documentID: String, fact: Fact, imageURL: String, introSentence: String?, description: String, moreInformationLink: String?) {     /// For the InfoHeaderAddOnCell initialization
        
        let info = AddOnInfoHeader(description: description, imageURL: imageURL, introSentence: introSentence, moreInformationLink: moreInformationLink)
        self.style = style
        self.addOnInfoHeader = info
        self.documentID = documentID
        self.description = description
        self.imageURL = imageURL
        self.fact = fact
        self.OP = OP
    }
    
    
    func getFact(documentID: String) {
        print("Get Fact: \(documentID)")
        let ref = db.collection("Facts").document(documentID)
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let document = snap {
                    if let data = document.data() {
                        guard let name = data["name"] as? String else {
                            return
                        }
                        
                        let fact = Fact()
                        fact.documentID = document.documentID
                        fact.title = name
                        
                        if let imageURL = data["imageURL"] as? String { // Not mandatory
                            fact.imageURL = imageURL
                        }
                        if let description = data["description"] as? String {   // Was introduced later on
                            fact.description = description
                        }
                        if let displayType = data["displayOption"] as? String { // Was introduced later on
                            if displayType == "topic" {
                                fact.displayOption = .topic
                            } // else { .fact
                        }
                        fact.fetchComplete = true
                        
                        self.singleTopic = fact
                    }
                }
            }
        }
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
                let ref = self.db.collection("Facts").document(self.fact.documentID).collection("addOns").document(self.documentID).collection("items").order(by: "createDate", descending: true).limit(to: 10)
                
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
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: fact)
                                    
                                    self.items.append(item)
                                } else if type == "topicPost" {
                                    let post = Post()
                                    post.documentID = document.documentID
                                    post.isTopicPost = true
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: post)
                                    self.items.append(item)
                                } else {    // Post
                                    let post = Post()
                                    post.documentID = document.documentID
                                    
                                    if let postDescription = data["title"] as? String {
                                        post.addOnTitle = postDescription
                                    }
                                    
                                    let item = AddOnItem(documentID: document.documentID, item: post)
                                    self.items.append(item)
                                }
                            }
                            DispatchQueue.main.async {
                                self.delegate?.done()
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

