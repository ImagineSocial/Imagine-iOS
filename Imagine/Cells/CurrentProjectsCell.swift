//
//  CurrentProjectsCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class CurrentProjectsCell: UITableViewCell {
    
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var fourthLabel: UILabel!
    
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var thirdView: UIView!
    @IBOutlet weak var fourthView: UIView!
    
    let db = Firestore.firestore()
    
    override func awakeFromNib() {
        
        let views = [firstView!, secondView!, thirdView!, fourthView!]
        let labels = [firstLabel!, secondLabel!, thirdLabel!, fourthLabel!]
        
        for view in views {
            view.layer.cornerRadius = 4
            if #available(iOS 13.0, *) {
                view.layer.borderColor = UIColor.quaternarySystemFill.cgColor
            } else {
                view.layer.borderColor = UIColor(red: 116.0, green: 116.0, blue: 128.0, alpha: 0.08).cgColor
            }
            view.layer.borderWidth = 1
        }
        
        getData(labels: labels)
    }
    
    func getData(labels: [UILabel]) {
        let ref = db.collection("TopTopicData").document("CurrentProjects")
        
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
