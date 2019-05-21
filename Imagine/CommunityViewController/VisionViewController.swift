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
    
    var visionText = ""
    
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
    
    @IBAction func visionDetailTapped(_ sender: DesignableButton) {
        switch sender.tag {
        case 0: visionText = "vision"
            break
        case 1: visionText = "step1"
            break
        case 2: visionText = "step2"
            break
        case 3: visionText = "step3"
            break
        case 4: visionText = "step4"
            break
        case 5: visionText = "step5"
            break
        default:
            visionText = ""
        }
        
        performSegue(withIdentifier: "toVisionDetail", sender: nil)
    }
    
 
    
    @IBAction func moreInfoPressed(_ sender: Any) {
        if let parentVC = self.parent as? PageViewController {
            parentVC.setViewControllers([parentVC.pages[1]], direction: UIPageViewController.NavigationDirection.forward, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? VisionDetailViewController {
            nextVC.visionText = self.visionText
        }
    }
    
}
