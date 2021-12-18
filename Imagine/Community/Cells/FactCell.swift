//
//  FactCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class FactCell: BaseCollectionViewCell {
    
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var factDescriptionLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    let db = Firestore.firestore()
    
    static let identifier = "FactCell"
    
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
    
    override func awakeFromNib() {
                
        contentView.clipsToBounds = false
    }
    
    override func prepareForReuse() {
        factCellImageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        containerView.layer.cornerRadius = Constants.communityCornerRadius
    }
    
    var fact: Community? {
        didSet {
            if let fact = fact {
                factCellLabel.text = fact.title
                factDescriptionLabel.text = fact.description
                
                if let url = URL(string: fact.imageURL) {
                    factCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-community"), options: [], completed: nil)
                } else {
                    factCellImageView.image = UIImage(named: "default-community")
                }
            }
        }
    }
    
    var unloadedFact: Community? {
        didSet {
            if let unloadedFact = unloadedFact, unloadedFact.documentID != "" {
                var collectionRef: CollectionReference!
                let language = LanguageSelection().getLanguage()
                if language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                let ref = collectionRef.document(unloadedFact.documentID)
                
                let user = Auth.auth().currentUser
                ref.getDocument { (snap, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let snap = snap {
                            if let data = snap.data() {
                                if let fact = CommunityHelper().getCommunity(currentUser: user,documentID: snap.documentID, data: data) {
                                    
                                    self.fact = fact
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
