//
//  InfoViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {
    
    @IBOutlet weak var dismissButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = navigationController {
            self.dismissButton.isHidden = true
        }
        
    }
    

    @IBAction func backPressed(_ sender: Any) {
        if let parentVC = self.parent as? PageViewController {
            parentVC.setViewControllers([parentVC.pages[0]], direction: .reverse, animated: true, completion: nil)
        }
    }
    @IBAction func dismissButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

