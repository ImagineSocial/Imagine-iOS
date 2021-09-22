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
    let cornerRadius: CGFloat = 6
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
        }
    }

    func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ?
                CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) :
                CGAffineTransform.identity
        })
    }
    
    var fact: Community? {
        didSet {
            guard let fact = fact else { return }
            
            self.getArguments(fact: fact)
            
            if let url = URL(string: fact.imageURL) {
                topicImageView.sd_setImage(with: url, completed: nil)
            } else {
                topicImageView.image = UIImage(named: "default-community")
            }
            topicNameLabel.text = fact.title
            topicDescriptionLabel.text = fact.description
                     
            
        }
    }
    
    override func layoutSubviews() {
        contentView.layer.cornerRadius = cornerRadius
        layer.cornerRadius = cornerRadius
        layer.shadowColor = UIColor.label.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.4
        layer.shadowPath = UIBezierPath(roundedRect: contentView.frame, cornerRadius: cornerRadius).cgPath
    }
    
    func getArguments(fact: Community) {
        if fact.documentID == "" { return }
        
        var collectionRef: CollectionReference!
        
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        
        let ref = collectionRef.document(fact.documentID).collection("arguments")
        
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
