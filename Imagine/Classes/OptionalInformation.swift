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

class OptionalInformation {
    
    var style: OptionalInformationStyle
    var headerTitle: String?
    var description: String?
    var documentID: String?  // DocumentID of the addOn
    var fact: Fact?
    var addOnInfoHeader: AddOnInfoHeader?
    
    let db = Firestore.firestore()
    
    var delegate: OptionalInformationDelegate?
    
    var items = [Any]()
    
    init(style: OptionalInformationStyle, headerTitle: String, description: String, documentID: String, fact: Fact) {    /// For the normal AddOn initialization
        self.description = description
        self.headerTitle = headerTitle
        self.documentID = documentID
        self.fact = fact
        self.style = style
    }
    
    init(style: OptionalInformationStyle, introSentence: String?, description: String, moreInformationLink: String?) {     /// For the InfoHeaderAddOnCell initialization
        let info = AddOnInfoHeader(description: description, introSentence: introSentence, moreInformationLink: moreInformationLink)
        self.style = style
        self.addOnInfoHeader = info
    }
    
    init(style: OptionalInformationStyle, headerTitle: String, description: String, factDocumentID: String) {
        self.style = style
        getFact(documentID: factDocumentID)
        self.headerTitle = headerTitle
        self.description = description
    }
    
    init(newAddOnStyle: OptionalInformationStyle) { // For the NewAddOnTableViewController
        
        self.style = newAddOnStyle
        
        switch newAddOnStyle {
        case .all:
            self.headerTitle = "Füge eine Kollektion mit Beiträgen und Themen hinzu"
            self.description = Constants.texts.AddOns.collectionText
            
        case .justPosts:
            self.headerTitle = "Füge eine Reihe an Posts hinzu:"
            let post = Post()
            post.title = "Beiträge für Beginner zum lernen"
            let post2 = Post()
            post2.title = "Beiträge zum lernen für Beginner"
            
            self.items.append(contentsOf: [post, post2])
        case .justTopics:
            self.headerTitle = "Füge eine Reihe an Themen hinzu:"
            let topic = Fact()
            topic.title = "Verbreite spannende Themen mit den Usern"
            topic.displayOption = .topic
            
            self.items.append(topic)
        case .header:
            self.headerTitle = "Füge einen Header hinzu"
            self.description = Constants.texts.AddOns.headerText
            
        case .singleTopic:
            self.headerTitle = "Verlinke ein Aussagekräfigtes Thema!"
            self.description = Constants.texts.AddOns.singleTopicText
        }
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
                        
                        if let imageURL = data["imageURL"] as? String { // Not mandatory (in fact not selectable)
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
                
                        self.fact = fact
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
        
        print("Get Items bei ", fact?.title)
        guard let fact = fact, let documentID = documentID else {
            print("Not enough info in OptionalInformation getItems")
            return
        }
        
        let ref = db.collection("Facts").document(fact.documentID).collection("addOns").document(documentID).collection("items").limit(to: 10)
        
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
                            
                            self.items.append(fact)
                        } else if type == "topicPost" {
                            let post = Post()
                            post.documentID = document.documentID
                            post.isTopicPost = true
                            
                            self.items.append(post)
                        } else {    // Post
                            let post = Post()
                            post.documentID = document.documentID
                            
                            if let postDescription = data["title"] as? String {
                                post.addOnTitle = postDescription
                            }
                            self.items.append(post)
                        }
                    }
                    self.delegate?.done()
                }
            }
        }
    }
}

