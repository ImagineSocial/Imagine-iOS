//
//  WhyGuiltyCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class SmallFactCell: UICollectionViewCell {
    
    @IBOutlet weak var factImageView: UIImageView!
    @IBOutlet weak var factHeaderTitle: UILabel!
    @IBOutlet weak var factHeaderDescriptionLabel: UILabel!
    @IBOutlet weak var firstArgumentLabel: UILabel!
    @IBOutlet weak var secondArgumentLabel: UILabel!
    @IBOutlet weak var firstArgumentUpvoteCount: UILabel!
    @IBOutlet weak var secondArgumentUpvoteCount: UILabel!
    
    
    let db = Firestore.firestore()
    let dataHelper = DataHelper()
    
    var fact: Fact? {
        didSet {
            guard let fact = fact else { return }
            
            self.getArguments(documentID: fact.documentID)
            
            if let url = URL(string: fact.imageURL) {
                factImageView.sd_setImage(with: url, completed: nil)
            } else {
                factImageView.image = UIImage(named: "FactStamp")
            }
            factHeaderTitle.text = fact.title
            factHeaderDescriptionLabel.text = fact.description
                        
        }
    }
    
    var factID: String? {
        didSet {
            let ref = db.collection("Facts").document(factID!)
            
            self.getArguments(documentID: factID!)
            
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let data = snap.data() {
                            if let fact = self.dataHelper.addFact(data: data) {
                                fact.documentID = snap.documentID
                                
                                self.fact = fact
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getArguments(documentID: String) {
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
                firstArgumentLabel.text = title
                
                let upvotesCompined = -downvotes+upvotes
                firstArgumentUpvoteCount.text = String(upvotesCompined)
            } else {
                secondArgumentLabel.text = title
                
                let upvotesCompined = -downvotes+upvotes
                secondArgumentUpvoteCount.text = String(upvotesCompined)
            }
            
        }
    }
    
    
    override func awakeFromNib() {
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .secondarySystemBackground
        } else {
            contentView.backgroundColor = .ios12secondarySystemBackground
        }
        
        layoutIfNeeded()
        
        contentView.layer.cornerRadius = 6
        factImageView.layer.cornerRadius = 4
        backgroundColor = .clear
    }
    
}
