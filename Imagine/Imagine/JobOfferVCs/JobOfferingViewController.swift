//
//  JobOfferingViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
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
        let text = NSLocalizedString("helpVC_interested_label", comment: "")
        interestedCountLabel.text = String.localizedStringWithFormat(text, jobOffer.interested)    // Damit er nach dem Bewerben updatet
    }
    
    func setJobOffer() {
        if jobOffer.documentID != "" {
//            headerLabel.text = jobOffer.title
            self.navigationItem.title = jobOffer.title
            smallBodyLabel.text = jobOffer.cellText
            
            let newLineString = "\n"    // Need to hardcode this and replace the \n of the fetched text
            let descriptionText = jobOffer.descriptionText.replacingOccurrences(of: "\\n", with: newLineString)
            fullBodyLabel.text = descriptionText
        } else {    // Also "Wir brauchen dich!"
//            headerLabel.text = "Wir brauchen dich!"
            self.navigationItem.title = NSLocalizedString("helpVC_entry_title", comment: "")
            smallBodyLabel.text = NSLocalizedString("helpVC_entry_summary", comment: "")
            fullBodyLabel.text = NSLocalizedString("helpVC_entry_description", comment: "")
        }
        
    }

 
    @IBAction func interestedPressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toSurveySegue", sender: jobOffer)
        } else {
            self.notLoggedInAlert()
        }
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
