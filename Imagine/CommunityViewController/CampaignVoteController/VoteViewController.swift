//
//  VoteViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.08.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class VoteViewController: UIViewController, ReachabilityObserverDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var voteTillDateLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var impactDescriptionLabel: UILabel!
    @IBOutlet weak var impactLabel: UILabel!
    @IBOutlet weak var costDescriptionLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var realizationTimeDescriptionLabel: UILabel!
    @IBOutlet weak var timeToRealizationLabel: UILabel!
    @IBOutlet weak var vetoButton: DesignableButton!
    @IBOutlet weak var supportButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    

    @IBOutlet weak var voteTillDateView: UIView!
    @IBOutlet weak var impactView: UIView!
    @IBOutlet weak var costView: UIView!
    @IBOutlet weak var realizationTimeView: UIView!
    
    var vote:Vote?
    let handyHelper = HandyHelper()
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        presentVote()
        
        voteTillDateView.layer.cornerRadius = 6
        
        impactView.layer.cornerRadius = 4
        costView.layer.cornerRadius = 4
        realizationTimeView.layer.cornerRadius = 4
    }
    
    func presentVote() {
        guard let vote = vote else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        self.navigationItem.title = vote.title
        subtitleLabel.text = vote.subtitle
        voteTillDateLabel.text = vote.endOfVoteDate
        descriptionLabel.text = vote.description
        switch vote.impact {
        case .light:
            impactLabel.text = "Leicht"
            impactLabel.textColor = .green
        case .medium:
            impactLabel.text = "Mittel"
            impactLabel.textColor = .orange
        case .strong:
            impactLabel.text = "Stark"
            impactLabel.textColor = .red
        
        }
        impactDescriptionLabel.text = vote.impactDescription
        costLabel.text = vote.cost
        costDescriptionLabel.text = vote.costDescription
        timeToRealizationLabel.text = "\(vote.timeToRealization) Monate"
        realizationTimeDescriptionLabel.text = vote.realizationTimeDescription
    }
    
    @IBAction func vetoButtonTapped(_ sender: Any) {
        checkIfAllowedToVote(supporter: false)
    }
    
    @IBAction func supportButtonTapped(_ sender: Any) {
        checkIfAllowedToVote(supporter: true)
    }
    
    func reachabilityChanged(_ isReachable: Bool) {
        print(" Connection?: ", isReachable)
    }
    
    func checkIfAllowedToVote(supporter: Bool) {
        if isConnected() {
        if let user = Auth.auth().currentUser {
            if let vote = vote {
                let voteRef = db.collection("Votes").document(vote.documentID)
                voteRef.getDocument { (doc, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let document = doc {
                            if let docData = document.data() {
                                if let voters = docData["voters"] as? [String] {
                                    for voter in voters {
                                        if voter == user.uid {
                                            self.alert(message: "Jeder User hat nur eine Stimme für jede Abstimmung!", title: "Du hast bereits gewählt")
                                            return
                                        }
                                    }
                                    // Not in the list
                                    self.allowedToVote(supporter: supporter)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            self.notLoggedInAlert()
        }
        } else {
            self.alert(message: "Du brauchst eine aktive Internet Verbindung um wählen zu können!")
        }
    }
    
    func allowedToVote(supporter: Bool) {
        let alertController = UIAlertController(title: "Bereit zum wählen?", message: "Du kannst nur einmal an einer Abstimmung teilnehmen und kannst deine Meinung im Nachhinein nicht ändern!", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .destructive, handler: { (_) in
            alertController.dismiss(animated: true, completion: nil)
        })
        let stayAction = UIAlertAction(title: "Ich bin mir sicher!", style: .cancel) { (_) in
            self.voted(supporter: supporter)
        }
        alertController.addAction(stayAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func voted(supporter: Bool) {
        if let user = Auth.auth().currentUser {
            if let vote = vote {
                
                self.view.activityStartAnimating()
                
                let voteRef = db.collection("Votes").document(vote.documentID)
                
                voteRef.getDocument { (document, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let document = document {
                            if let docData = document.data() {
                                if let vetoCount = docData["vetoCount"] as? Double, let supportCount = docData["supportCount"] as? Double {
                                    
                                    if supporter {
                                        let newSupportCount = supportCount+1
                                        
                                        voteRef.updateData(["supportCount": newSupportCount], completion: { (err) in
                                            if let error = err {
                                                print("We have an error: \(error.localizedDescription)")
                                            } else {
                                                self.registerVoter(userUID: user.uid)
                                            }
                                        })
                                    } else {
                                        let newVetoCount = vetoCount+1
                                        
                                        voteRef.updateData(["vetoCount": newVetoCount], completion: { (err) in
                                            if let error = err {
                                                print("We have an error: \(error.localizedDescription)")
                                            } else {
                                                self.registerVoter(userUID: user.uid)
                                            }
                                        })
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func registerVoter(userUID: String) {
        if let vote = vote {
            let voteRef = db.collection("Votes").document(vote.documentID)
            
            voteRef.updateData([
                "voters": FieldValue.arrayUnion([userUID]) // Add the person as a voter
            ]) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                    self.alert(message: "Deine Stimme wurde angenommen.", title: "Danke für deine Unterstützung!")
                    self.vetoButton.isEnabled = false
                    self.supportButton.isEnabled = false
                }
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.voteDetailText)
    }
}
