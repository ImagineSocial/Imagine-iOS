//
//  FactCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class FactCell:UICollectionViewCell {
    
    @IBOutlet weak var factCellLabel: UILabel!
    @IBOutlet weak var factCellImageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var factDescriptionLabel: UILabel!
    @IBOutlet weak var followButton: DesignableButton!
    @IBOutlet weak var containerView: UIView!
    
    let db = Firestore.firestore()
    let cornerRadius: CGFloat = 6
    
    override func awakeFromNib() {
        
        layer.cornerRadius = cornerRadius
        containerView.layer.cornerRadius = cornerRadius
        
        contentView.clipsToBounds = false
    }
    
    override func prepareForReuse() {
        factCellImageView.image = nil
        followButton.setImage(UIImage(named: "AddPost"), for: .normal)
    }
    
    override func layoutSubviews() {
        if #available(iOS 13.0, *) {
            layer.shadowColor = UIColor.label.cgColor
        } else {
            layer.shadowColor = UIColor.black.cgColor
        }
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 2
        layer.shadowOpacity = 0.4
        layer.shadowPath = UIBezierPath(roundedRect: contentView.frame, cornerRadius: cornerRadius).cgPath
    }
    
    var fact: Fact? {
        didSet {
            if let fact = fact {
                factCellLabel.text = fact.title
                factDescriptionLabel.text = fact.description
                
                if fact.beingFollowed {
                    followButton.setImage(UIImage(named: "greenTik"), for: .normal)
                }
                
                if let url = URL(string: fact.imageURL) {
                    factCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "FactStamp"), options: [], completed: nil)
                } else {
                    factCellImageView.image = UIImage(named: "FactStamp")
                }
            }
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
                            if let fact = DataHelper().addFact(documentID: snap.documentID, data: data) {
                                
                                self.fact = fact
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func followButtonTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            if let fact = fact {
                if !fact.beingFollowed {
                    let parentVC = FactParentContainerViewController()
                    parentVC.followTopic(fact: fact)
                    
                    followButton.setImage(UIImage(named: "greenTik"), for: .normal)
                }
            }
        }
    }
}
