//
//  VisionViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class VisionViewController: UIViewController {

    @IBOutlet weak var cobraButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!

    
    var visionText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        headerLabel.layer.masksToBounds = true
        headerLabel.layer.cornerRadius = 15
        
        headerLabel.layer.borderWidth = 1
        headerLabel.layer.borderColor = UIColor.black.cgColor
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 3
        view.addGestureRecognizer(tap)
        cobraButton.isEnabled = false
        cobraButton.alpha = 0
    }
    
    @objc func doubleTapped() {
        
        
        
            UIView.animate(withDuration: 4, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveEaseOut, animations: {
                self.headerLabel.alpha = 0
                self.cobraButton.alpha = 1
            }, completion: { (_) in
                self.headerLabel.isHidden = true
                self.cobraButton.isEnabled = true
            })
        
        
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
    
 
    @IBAction func backToCommunityTapped(_ sender: Any) {
        if let parentVC = self.parent as? PageViewController {
            parentVC.setViewControllers([parentVC.pages[0]], direction: .reverse, animated: true, completion: nil)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? VisionDetailViewController {
            nextVC.visionText = self.visionText
        }
    }
    
}
