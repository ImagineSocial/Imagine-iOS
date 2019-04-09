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
    @IBOutlet weak var moreInfoButton: DesignableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        headerLabel.layer.masksToBounds = true
        headerLabel.layer.cornerRadius = 15
        
        headerLabel.layer.borderWidth = 1
        headerLabel.layer.borderColor = UIColor.black.cgColor
        
        moreInfoButton.layer.masksToBounds = true
        moreInfoButton.layer.borderWidth = 0.1
        moreInfoButton.layer.borderColor = UIColor.black.cgColor
        
        
    }
 
    
    @IBAction func moreInfoPressed(_ sender: Any) {
        if let parentVC = self.parent as? PageViewController {
            parentVC.setViewControllers([parentVC.pages[1]], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        }
        
        
    }
    
}
