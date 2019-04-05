//
//  VisionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class VisionViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        headerLabel.layer.masksToBounds = true
        headerLabel.layer.cornerRadius = 15
        
        headerLabel.layer.borderWidth = 1
        headerLabel.layer.borderColor = UIColor.black.cgColor
    }
 
    
    
}
