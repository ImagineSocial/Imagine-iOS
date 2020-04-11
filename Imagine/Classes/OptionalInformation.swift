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

class OptionalInformation {
    
    var headerTitle: String
    var description: String
    var documentID: String
    var fact: Fact
    
    let db = Firestore.firestore()
    
    var delegate: OptionalInformationDelegate?
    
    var items = [Any]()
    
    init(headerTitle: String, description: String, documentID: String, fact: Fact) {
        self.description = description
        self.headerTitle = headerTitle
        self.documentID = documentID
        self.fact = fact
    }
    
    func getItems() {
        let ref = db.collection("Facts").document(fact.documentID).collection("addOns").document(documentID).collection("items")
        
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

