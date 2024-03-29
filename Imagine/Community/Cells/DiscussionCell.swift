//
//  DiscussionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 13.05.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class DiscussionCell: BaseCollectionViewCell {
    
    @IBOutlet weak var topicImageView: DesignableImage!
    @IBOutlet weak var topicNameLabel: UILabel!
    @IBOutlet weak var topicDescriptionLabel: UILabel!
    
    @IBOutlet weak var proArgumentLabel: UILabel!
    @IBOutlet weak var proArgumentCountLabel: UILabel!
    @IBOutlet weak var contraArgumentLabel: UILabel!
    @IBOutlet weak var contraArgumentCountLabel: UILabel!
    
    let db = FirestoreRequest.shared.db
    
    override var isHighlighted: Bool {
        didSet {
            toggleIsHighlighted()
        }
    }
    
    override func awakeFromNib() {
        cornerRadius = 8
    }

    func toggleIsHighlighted() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
            self.alpha = self.isHighlighted ? 0.9 : 1.0
            self.transform = self.isHighlighted ?
                CGAffineTransform.identity.scaledBy(x: 0.97, y: 0.97) :
                CGAffineTransform.identity
        })
    }
    
    var community: Community? {
        didSet {
            guard let community = community else { return }
            
            self.getArguments(community: community)
            
            if let imageURL = community.imageURL, let url = URL(string: imageURL) {
                topicImageView.sd_setImage(with: url, completed: nil)
            } else {
                topicImageView.image = UIImage(named: "default-community")
            }
            topicNameLabel.text = community.title
            topicDescriptionLabel.text = community.description
                     
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.layer.cornerRadius = cornerRadius ?? Constants.cellCornerRadius
    }
    
    func getArguments(community: Community) {
        guard let communityID = community.id else { return }
        
        let argumentReference = FirestoreCollectionReference(document: communityID, collection: "arguments")
        let proReference = FirestoreReference.collectionRef(.communities, collectionReferences: argumentReference, queries: FirestoreQuery(field: "proOrContra", equalTo: "pro"), FirestoreQuery(field: "upvotes", limit: 1))
        
        proReference.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    self.addArgumentFromSnap(snapshot: snap)
                }
            }
        }
        
        let contraReference = FirestoreReference.collectionRef(.communities, collectionReferences: argumentReference, queries: FirestoreQuery(field: "proOrContra", equalTo: "pro"), FirestoreQuery(field: "upvotes", limit: 1))
        
        contraReference.getDocuments { (snap, err) in
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
