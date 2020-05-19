//
//  DiscussionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class DiscussionCell: UICollectionViewCell {
    
    @IBOutlet weak var topicImageView: DesignableImage!
    @IBOutlet weak var topicNameLabel: UILabel!
    @IBOutlet weak var topicDescriptionLabel: UILabel!
    
    @IBOutlet weak var proArgumentLabel: UILabel!
    @IBOutlet weak var proArgumentCountLabel: UILabel!
    @IBOutlet weak var contraArgumentLabel: UILabel!
    @IBOutlet weak var contraArgumentCountLabel: UILabel!
    
    let db = Firestore.firestore()
    
    var fact: Fact? {
        didSet {
            guard let fact = fact else { return }
            
            self.getArguments(documentID: fact.documentID)
            
            if let url = URL(string: fact.imageURL) {
                topicImageView.sd_setImage(with: url, completed: nil)
            } else {
                topicImageView.image = UIImage(named: "FactStamp")
            }
            topicNameLabel.text = fact.title
            topicDescriptionLabel.text = fact.description
                     
            
        }
    }
    
    override func awakeFromNib() {
        
        layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.secondaryLabel.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
        layer.borderWidth = 0.5
        
        layer.cornerRadius = 6
        backgroundColor = .clear
    }
    
    func getArguments(documentID: String) {
        if documentID == "" { return }
        
        let ref = db.collection("Facts").document(documentID).collection("arguments")
        
        let proRef = ref.whereField("proOrContra", isEqualTo: "pro").order(by: "upvotes", descending: true).limit(to: 1)
        proRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    self.addArgumentFromSnap(snapshot: snap)
                }
            }
        }
        
        let contraRef = ref.whereField("proOrContra", isEqualTo: "contra").order(by: "upvotes", descending: true).limit(to: 1)
        contraRef.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    self.addArgumentFromSnap(snapshot: snap)
                }
            }
        }
        
    }
    
    func addArgumentFromSnap(snapshot: QuerySnapshot) {
        for document in snapshot.documents {
            let data = document.data()
            
            guard let title = data["title"] as? String, let proOrContra = data["proOrContra"] as? String, let upvotes = data["upvotes"] as? Int, let downvotes = data["downvotes"] as? Int else {
                return
            }
            if proOrContra == "pro" {
                proArgumentLabel.text = title
                
                let upvotesCompined = -downvotes+upvotes
                proArgumentCountLabel.text = String(upvotesCompined)
            } else {
                contraArgumentLabel.text = title
                
                let upvotesCompined = -downvotes+upvotes
                contraArgumentCountLabel.text = String(upvotesCompined)
            }
            
        }
    }
    
}
