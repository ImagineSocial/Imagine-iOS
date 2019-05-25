//
//  ArgumentDetailViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ArgumentDetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var commentaryView: UIView!
    @IBOutlet weak var commentaryView2: UIView!
    @IBOutlet weak var commentaryView3: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commentaryView.layer.cornerRadius = 5
        commentaryView2.layer.cornerRadius = 5
        commentaryView3.layer.cornerRadius = 5
        
    }
    

    @IBAction func backTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}
