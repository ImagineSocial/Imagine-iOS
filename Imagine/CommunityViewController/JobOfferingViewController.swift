//
//  JobOfferingViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

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
        interestedCountLabel.text = "\(jobOffer.interested) sind interessiert"     // Damit er nach dem Bewerben updatet
    }
    
    func setJobOffer() {
        if jobOffer.documentID != "" {
            headerLabel.text = jobOffer.title
            smallBodyLabel.text = jobOffer.cellText
            
            let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
            let descriptionText = jobOffer.descriptionText.replacingOccurrences(of: "\\n", with: newLineString)
            fullBodyLabel.text = descriptionText
        } else {    // Also "Wir brauchen dich!"
            headerLabel.text = "Wir brauchen dich!"
            smallBodyLabel.text = "Wenn du glaubst, mit deinem Wissen kannst du uns helfen, aber es gibt keine passende Ausschreibung, gib uns Bescheid! Wir sind auf klüge Köpfe angewiesen!"
            fullBodyLabel.text = "Schreib uns einfach, welcher Bereich dich besonders interessiert und deine Motivation.\n\n Wir würden uns freuen"
        }
        
    }

 
    @IBAction func interestedPressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toSurveySegue", sender: jobOffer)
        } else {
            self.notLoggedInAlert()
        }
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
