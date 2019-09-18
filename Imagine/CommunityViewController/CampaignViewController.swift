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
import EasyTipView

class CampaignViewController: UIViewController, ReachabilityObserverDelegate, EasyTipViewDelegate {
    
    

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var shortBodyLabel: UILabel!
    @IBOutlet weak var longBodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var oppositionLabel: UILabel!
    @IBOutlet weak var supportButton: DesignableButton!
    @IBOutlet weak var oppositionButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var campaign = Campaign()
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        showCampaign()
    }
    
    func showCampaign() {
        headerLabel.text = campaign.title
        shortBodyLabel.text = campaign.cellText
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
    
    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        print("Dismissed")
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        var preferences = EasyTipView.Preferences()
        preferences.drawing.font = UIFont(name: "IBMPlexSans", size: 18)!
        preferences.drawing.foregroundColor = UIColor.white
        preferences.drawing.backgroundColor = Constants.imagineColor
        preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
        preferences.positioning.bubbleHInset = 10
        preferences.positioning.bubbleVInset = 10
        preferences.positioning.maxWidth = self.view.frame.width-40
        // Maximum of 800 Words
        
        let voteInfoText = "Ihr entscheidet selbst, was die genaue Bedeutung der Buttons sind. Wir finden, diese 4 Emotionen rund um 'danke', 'wow, 'ha' und 'nice' decken die gängigsten Reaktionen auf Beiträge ab. Wir werden sicherlich noch gemeinsam entscheiden, wie man die gesamte Darstellung und Interaktion überarbeiten kann."
        
        
        
//        EasyTipView(text: "Hallo Moin", preferences: preferences, delegate: self)
//        EasyTipView(contentView: self.headerLabel, preferences: preferences, delegate: self)
        let text = "Hallo Moin Along with texting, emojis, and stickers, GIFs are de rigueur when it comes to instant digital communication. Adding a GIF button to a chat or messaging feature in your app or to a social posting feature is a quick and easy way to boost engagement in your app with exciting GIF content. This includes GIF search and GIF reaction categories.\n /n/n \n A few great use cases are messaging apps, dating apps, or workplace collaboration apps. The iOS SDK (GfycatKit) and Android SDK (Gfycat Picker Fragment) were developed for these use cases and have UI elements and analytics already included. To use the Gfycat “GIF” button icon, you can find a .svg here. The SDKs are also ad-enabled (off by default). If you’d like to plug this in as well, send us a note to api@gfycat.com during your development process. Hallo Moin"
        
        print("TextCount: ", text.count)
        EasyTipView.show(animated: true, forItem: infoButton, withinSuperview: nil, text: text, preferences: preferences, delegate: self)
    }
    
}
