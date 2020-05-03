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

enum OptionalInformationType{
    case justPosts
    case justTopics
    case all
    case header
}

class OptionalInformation {
    
    var headerTitle: String?
    var description: String?
    var documentID: String?  // DocumentID of the addOn
    var fact: Fact?
    var addOnInfoHeader: AddOnInfoHeader?
    var style: OptionalInformationType?
    
    let db = Firestore.firestore()
    
    var delegate: OptionalInformationDelegate?
    
    var items = [Any]()
    
    init(headerTitle: String, description: String, documentID: String, fact: Fact) {    /// For the normal AddOn initialization
        self.description = description
        self.headerTitle = headerTitle
        self.documentID = documentID
        self.fact = fact
    }
    
    init(introSentence: String?, description: String, moreInformationLink: String?) {     /// For the InfoHeaderAddOnCell initialization
        let info = AddOnInfoHeader(description: description, introSentence: introSentence, moreInformationLink: moreInformationLink)
        
        self.addOnInfoHeader = info
    }
    
    init(newAddOnStyle: OptionalInformationType) {
        
        self.style = newAddOnStyle
        
        switch newAddOnStyle {
        case .all:
            self.headerTitle = "Füge eine Kollektion mit Beiträgen und Themen hinzu"
            let post = Post()
            post.title = "Beiträge aller Art können dein Thema mit Leben ausfüllen!"
            post.type = .picture
            post.imageURL = "https://firebasestorage.googleapis.com/v0/b/imagine-6214f.appspot.com/o/postPictures%2FON8vMxvYuQPJC9XXpYDc.png?alt=media&token=c5594d8a-d7f0-437a-97fd-d56f4cf77a13"
            
            let fact = Fact(addMoreDataCell: false)
            fact.title = "So Interessant"
            fact.displayOption = .topic
            fact.description = "Erweitere das Wissen deiner Mitmenschen"
            fact.imageURL = "https://firebasestorage.googleapis.com/v0/b/imagine-6214f.appspot.com/o/postPictures%2FyCP4UvE51etbGxXtspIb.png?alt=media&token=77909657-7548-432b-a5fc-d7204bb16fb9"
            fact.addOnTitle = "Verlinke andere relevante Themen für deine Mituser"
            
            self.items.append(contentsOf: [post, fact])
        case .justPosts:
            self.headerTitle = "Füge eine Reihe an Posts hinzu:"
            let post = Post()
            post.title = "Beiträge für Beginner zum lernen"
            let post2 = Post()
            post2.title = "Beiträge zum lernen für Beginner"
            
            self.items.append(contentsOf: [post, post2])
        case .justTopics:
            self.headerTitle = "Füge eine Reihe an Themen hinzu:"
            let topic = Fact(addMoreDataCell: false)
            topic.title = "Verbreite spannende Themen mit den Usern"
            topic.displayOption = .topic
            
            self.items.append(topic)
        case .header:
            let info = AddOnInfoHeader(description: "Hier kann eine ausführliche Einleitung zum Thema stehen, damit die Besucher des Themas sich schnell einen überblick verschaffen können.", introSentence: "Beschreibe dein Thema genauer", moreInformationLink: "Inklusive Link-Button")
            self.headerTitle = "Füge einen Header hinzu"
            
            self.addOnInfoHeader = info
        }
    }
    
    func getItems() {
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
                            let fact = Fact(addMoreDataCell: false)
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

