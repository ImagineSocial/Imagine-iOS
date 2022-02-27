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
import EasyTipView

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
    
    var tipView: EasyTipView?
    
    var vote:Vote?
    let handyHelper = HandyHelper.shared
    let db = FirestoreRequest.shared.db
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        presentVote()
        
        voteTillDateView.layer.cornerRadius = 6
        
        impactView.layer.cornerRadius = 4
        costView.layer.cornerRadius = 4
        realizationTimeView.layer.cornerRadius = 4
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
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
            impactLabel.text = NSLocalizedString("easy", comment: "easy")
            impactLabel.textColor = .green
        case .medium:
            impactLabel.text = NSLocalizedString("medium", comment: "medium")
            impactLabel.textColor = .orange
        case .strong:
            impactLabel.text = NSLocalizedString("strong", comment: "strong")
            impactLabel.textColor = .red
        
        }
        impactDescriptionLabel.text = vote.impactDescription
        costLabel.text = vote.cost
        costDescriptionLabel.text = vote.costDescription
        let string = NSLocalizedString("time_till_completion_in_month", comment: "... month")
        timeToRealizationLabel.text = String.localizedStringWithFormat(string, vote.timeToRealization)
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
                var collectionRef: CollectionReference!
                let language = LanguageSelection().getLanguage()
                if language == .english {
                    collectionRef = db.collection("Data").document("en").collection("votes")
                } else {
                    collectionRef = db.collection("Votes")
                }
                let voteRef = collectionRef.document(vote.documentID)
                voteRef.getDocument { (doc, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let document = doc {
                            if let docData = document.data() {
                                if let voters = docData["voters"] as? [String] {
                                    for voter in voters {
                                        if voter == user.uid {
                                            self.alert(message: NSLocalizedString("already_voted_message", comment: "just one vote"), title: NSLocalizedString("already_voted_title", comment: "just one"))
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
        let alertController = UIAlertController(title: NSLocalizedString("sure_to_vote_title", comment: "you sure?"), message: NSLocalizedString("sure_to_vote_message", comment: "just once and such"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: "cancle"), style: .destructive, handler: { (_) in
            alertController.dismiss(animated: true, completion: nil)
        })
        let stayAction = UIAlertAction(title: NSLocalizedString("i_am_sure", comment: "i am sure"), style: .cancel) { (_) in
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
                
                var collectionRef: CollectionReference!
                let language = LanguageSelection().getLanguage()
                if language == .english {
                    collectionRef = db.collection("Data").document("en").collection("votes")
                } else {
                    collectionRef = db.collection("Votes")
                }
                let voteRef = collectionRef.document(vote.documentID)
                
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
            var collectionRef: CollectionReference!
            let language = LanguageSelection().getLanguage()
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("votes")
            } else {
                collectionRef = db.collection("Votes")
            }
            let voteRef = collectionRef.document(vote.documentID)
            
            voteRef.updateData([
                "voters": FieldValue.arrayUnion([userUID]) // Add the person as a voter
            ]) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                    self.alert(message: NSLocalizedString("vote_successfull_alert_message", comment: ""), title: NSLocalizedString("thanks_for_support", comment: "thanks for support"))
                    self.vetoButton.isEnabled = false
                    self.supportButton.isEnabled = false
                }
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.voteDetailText)
            tipView!.show(forItem: infoButton)
        }
    }
}
