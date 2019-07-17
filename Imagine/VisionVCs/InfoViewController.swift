//
//  InfoViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    
    @IBOutlet weak var headerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

      headerLabel.layer.masksToBounds = true
        headerLabel.layer.cornerRadius = 15
        
    }
    

    @IBAction func backPressed(_ sender: Any) {
        if let parentVC = self.parent as? PageViewController {
            parentVC.setViewControllers([parentVC.pages[0]], direction: .reverse, animated: true, completion: nil)
        }
    }
    
}
