//
//  CurrentProjectsCollectionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class CurrentProjectsCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var thirdView: UIView!
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var fourthView: UIView!
        
    let db = FirestoreRequest.shared.db
        
    override func awakeFromNib() {
        
        let views = [firstView!, secondView!, thirdView!, fourthView!]
        let labels = [firstLabel!, secondLabel!, thirdLabel!, fourthLabel!]
        
        for view in views {
            view.layer.cornerRadius = 10
            view.layer.borderColor = UIColor.quaternarySystemFill.cgColor
            view.layer.borderWidth = 1
        }
        
        getData(labels: labels)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func getData(labels: [UILabel]) {
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .en {
            collectionRef = db.collection("Data").document("en").collection("topTopicData")
        } else {
            collectionRef = db.collection("TopTopicData")
        }
        let ref = collectionRef.document("CurrentProjects")
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    if let data = snap.data() {
                        if let workedOn = data["workedOn"] as? [String] {
                            var index = 0
                            for string in workedOn {
                                labels[index].text = string
                                index+=1
                            }
                        }
                     }
                }
            }
        }
    }
}
