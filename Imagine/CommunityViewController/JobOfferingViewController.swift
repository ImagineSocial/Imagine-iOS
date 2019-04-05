//
//  JobOfferingViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class JobOfferingViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var smallBodyLabel: UILabel!
    @IBOutlet weak var fullBodyLabel: UILabel!
    @IBOutlet weak var interestedCountLabel: UILabel!
    
    var jobOffer = JobOffer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setJobOffer()
    }
    
    func setJobOffer() {
        headerLabel.text = jobOffer.title
        smallBodyLabel.text = jobOffer.cellText
        interestedCountLabel.text = String(jobOffer.interested)
    }

 // toJobOfferSegue
    @IBAction func interestedPressed(_ sender: Any) {
    }
    @IBAction func moreInfosPressed(_ sender: Any) {
    }
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
