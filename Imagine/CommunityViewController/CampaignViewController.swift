//
//  CampaignViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 18.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class CampaignViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var shortBodyLabel: UILabel!
    @IBOutlet weak var longBodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var oppositionLabel: UILabel!
    @IBOutlet weak var supportButton: DesignableButton!
    @IBOutlet weak var oppositionButton: DesignableButton!
    
    var campaign = Campaign()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        showCampaign()
        self.navigationItem.title = campaign.category
    }
    
    func showCampaign() {
        headerLabel.text = campaign.title
        shortBodyLabel.text = campaign.cellText
        createDateLabel.text = campaign.createDate
        supporterLabel.text = "\(campaign.supporter) Supporter"
        oppositionLabel.text = "\(campaign.opposition) Vetos"
    }
    
    @IBAction func supportPressed(_ sender: Any) {
        let newSupporter = campaign.supporter+1
        
        let postRef = Firestore.firestore().collection("Campaigns")
        postRef.document(campaign.documentID).updateData(["campaignSupporter": newSupporter]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                let alert = UIAlertController(title: "Danke für deine Stimme!", message: "Jede Stimme zählt in einer ausgeglichenen Demokratie!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                self.present(alert, animated: true) {
                    
                }
                
                self.supporterLabel.text = "\(newSupporter) Supporter"
                self.supportButton.isEnabled = false
                self.oppositionButton.isEnabled = false
                print("Document successfully updated")
            }
        }
    }
    
    @IBAction func dontSupportPressed(_ sender: Any) {
        let newVetos = campaign.supporter-1
        
        let postRef = Firestore.firestore().collection("Campaigns")
        postRef.document(campaign.documentID).updateData(["campaignOpposition": newVetos]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                let alert = UIAlertController(title: "Danke für deine Stimme!", message: "Jede Stimme zählt in einer ausgeglichenen Demokratie!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                self.present(alert, animated: true) {
                    
                }
                self.oppositionLabel.text = "\(newVetos) Vetos"
                self.supportButton.isEnabled = false
                self.oppositionButton.isEnabled = false
                print("Document successfully updated")
            }
        }
    }
    
    @IBAction func reportPressed(_ sender: Any) {
    }
    
    
}
