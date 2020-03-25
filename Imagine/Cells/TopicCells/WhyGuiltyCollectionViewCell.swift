//
//  WhyGuiltyCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class WhyGuiltyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var factImageView: UIImageView!
    @IBOutlet weak var factHeaderTitle: UILabel!
    
    @IBOutlet weak var factHeaderDescriptionLabel: UILabel!
    
    @IBOutlet weak var firstArgumentLabel: UILabel!
    @IBOutlet weak var secondArgumentLabel: UILabel!
    
    let db = Firestore.firestore()
    let dataHelper = DataHelper()
    
    var fact: Fact? {
        didSet {
            guard let fact = fact else { return }
            
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
