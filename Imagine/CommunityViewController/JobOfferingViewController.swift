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
    
    override func viewWillAppear(_ animated: Bool) {
        interestedCountLabel.text = String(jobOffer.interested)     // Damit er nach dem Bewerben updatet
    }
    
    func setJobOffer() {
        if jobOffer.documentID != "" {
            headerLabel.text = jobOffer.title
            smallBodyLabel.text = jobOffer.cellText
        } else {    // Also "Wir brauchen dich!"
            headerLabel.text = "Wir brauchen dich!"
            smallBodyLabel.text = "Wenn du glaubst, mit deinem Wissen kannst du uns helfen, aber es gibt keine passende Ausschreibung, gib uns Bescheid! Wir sind auf klüge Köpfe angewiesen!"
        }
        
    }

 
    @IBAction func interestedPressed(_ sender: Any) {
        performSegue(withIdentifier: "toSurveySegue", sender: jobOffer)
    }
    @IBAction func moreInfosPressed(_ sender: Any) {
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSurveySegue" {
            if let job = sender as? JobOffer {
                if let surveyVC = segue.destination as? JobSurveyViewController {
                    surveyVC.jobOffer = job
                }
            }
        }
    }
    
}
