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
import FirebaseAuth
import EasyTipView

class CampaignViewController: UIViewController, ReachabilityObserverDelegate {
    

    @IBOutlet weak var shortBodyLabel: UILabel!
    @IBOutlet weak var longBodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var oppositionLabel: UILabel!
    @IBOutlet weak var supportButton: DesignableButton!
    @IBOutlet weak var oppositionButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var commentTableView: CommentTableView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var campaign = Campaign()
    let db = Firestore.firestore()
    
    var floatingCommentView: CommentAnswerView?
    
    var tipView: EasyTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showCampaign()
        
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        scrollViewTap.cancelsTouchesInView = false  // Otherwise the tap on the TableViews are not recognized
        scrollView.addGestureRecognizer(scrollViewTap)
        
        commentTableView.initializeCommentTableView(section: .proposal, notificationRecipients: nil)
        commentTableView.commentDelegate = self
        commentTableView.proposal = campaign
        
        createFloatingCommentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let view = floatingCommentView {
            view.removeFromSuperview()
        }
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    @objc func scrollViewTapped() {
        if let view = floatingCommentView {
            view.answerTextField.resignFirstResponder()
        }
    }
    
    func createFloatingCommentView() {
        let height = UIScreen.main.bounds.height
        floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: height-60, width: self.view.frame.width, height: 60))
        floatingCommentView!.delegate = self
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(floatingCommentView!)
        }
    }
    
    func showCampaign() {
        shortBodyLabel.text = campaign.cellText
        longBodyLabel.text = campaign.descriptionText
        createDateLabel.text = campaign.createDate
        supporterLabel.text = "\(campaign.supporter) Supporter"
        oppositionLabel.text = "\(campaign.opposition) Vetos"
    }
    
    @IBAction func supportPressed(_ sender: Any) {
        self.checkIfAllowedToVote(supporter: true)
    }
    
    @IBAction func dontSupportPressed(_ sender: Any) {
        self.checkIfAllowedToVote(supporter: false)
    }
    
    func reachabilityChanged(_ isReachable: Bool) {
        print("No Connection")
    }
    
    func voted(supporter: Bool) {
        let postRef = db.collection("Campaigns").document(campaign.documentID)
        
        if let user = Auth.auth().currentUser {
            if supporter {
                let newSupporter = campaign.supporter+1 // Could be the old number if anyone votes in between
                campaign.supporter = newSupporter
                
                postRef.updateData(["campaignSupporter": newSupporter]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        self.registerVoter(userUID: user.uid)
                    }
                }
            } else {
                let newVetos = campaign.opposition+1 // Could be the old number if anyone votes in between
                campaign.opposition = newVetos
                
                postRef.updateData(["campaignOpposition": newVetos]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        self.registerVoter(userUID: user.uid)
                    }
                }
            }
        }
    }
    
    func registerVoter(userUID: String) {
        
        let postRef = db.collection("Campaigns").document(campaign.documentID)
        
        postRef.updateData([
            "voters": FieldValue.arrayUnion([userUID]) // Add the person as a voter
        ]) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.view.activityStopAnimating()
                self.alert(message: "Deine Stimme wurde angenommen.", title: "Danke für deine Unterstützung!")
                self.oppositionLabel.text = "\(self.campaign.opposition) Vetos"
                self.supporterLabel.text = "\(self.campaign.supporter) Supporter"
                self.supportButton.isEnabled = false
                self.oppositionButton.isEnabled = false
                print("Document successfully updated")
            }
        }
        
    }
    
    func checkIfAllowedToVote(supporter: Bool) {
        if isConnected() {
            if let user = Auth.auth().currentUser {
                let voteRef = db.collection("Campaigns").document(campaign.documentID)
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
            } else {
                self.notLoggedInAlert()
            }
        } else {
            self.alert(message: "Du brauchst eine aktive Internet Verbindung um wählen zu können!")
        }
    }
    
    func allowedToVote(supporter: Bool) {
        let alertController = UIAlertController(title: "Bereit zum wählen?", message: "Du hast nur eine Stimme und kannst deine Meinung im Nachhinein nicht ändern!", preferredStyle: .alert)
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
    
    @IBAction func reportPressed(_ sender: Any) {
    }
    
    
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.campaignDetailText)
            tipView!.show(forItem: infoButton)
        }
    }
    
}

extension CampaignViewController: CommentViewDelegate, CommentTableViewDelegate {
    
    func recipientChanged(isActive: Bool, userUID: String) {
        print("COming soon")
    }
    
    func sendButtonTapped(text: String, isAnonymous: Bool) {
        floatingCommentView!.resignFirstResponder()
        commentTableView.saveCommentInDatabase(bodyString: text, isAnonymous: isAnonymous)
    }
    
    func commentTypingBegins() {
        
    }
    
    func doneSaving() {
        print("Done")
        if let view = floatingCommentView {
            view.answerTextField.text = ""
        }
    }
    
    func notLoggedIn() {
        self.notLoggedInAlert()
    }
    
    func notAllowedToComment() {
        if let view = floatingCommentView {
            view.answerTextField.text = ""
        }
    }
    
    func commentGotReported(comment: Comment) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let reportViewController = storyBoard.instantiateViewController(withIdentifier: "reportVC") as! MeldenViewController
        reportViewController.reportComment = true
        reportViewController.modalTransitionStyle = .coverVertical
        reportViewController.modalPresentationStyle = .overFullScreen
        self.present(reportViewController, animated: true, completion: nil)
    }
    
}
