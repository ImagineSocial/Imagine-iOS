//
//  JobSurveyViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import MessageUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class JobSurveyViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var introductionLabel: UILabel!
    @IBOutlet weak var qualificationLabel: UILabel!
    @IBOutlet weak var qualificationTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var residenceTextField: UITextField!
    @IBOutlet weak var inputTextField: UITextField!     //How much do you want to contribute?
    @IBOutlet weak var contactTextField: UITextField!
    @IBOutlet weak var messageTextField: UITextView!
    
    var jobOffer = JobOffer()
    var userName = ""
    var userUID = ""
    var send = false
    var jobTitle:String = ""
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        getUser()
    }
    
    func setUI() {
        scrollView.keyboardDismissMode = .onDrag
        messageTextField.layer.cornerRadius = 5
        let text = NSLocalizedString("jobSurvey_introduction_variable", comment: "")
        
        introductionLabel.text = String.localizedStringWithFormat(text, jobOffer.title)
        jobTitle = "as a \(jobOffer.title)"
        
        if jobOffer.documentID == "DDTMnbUAPco0gvWOkmvL" {   // Also Übersetzer
            qualificationLabel.text = "Bei welcher Sprache kannst du uns helfen Imagine zu übersetzen?"
        } else if jobOffer.documentID == "" {
            introductionLabel.text = NSLocalizedString("jobSurvey_introduction_label", comment: "")
            jobTitle = ""
        }
    }
    
    
    @IBAction func contactButtonTapped(_ sender: Any) {
        if qualificationLabel.text == "" || contactTextField.text == "" {
            introductionLabel.text = NSLocalizedString("jobSurvey_input_alert", comment: "")
            introductionLabel.textColor = .red
            scrollView.setContentOffset(.zero, animated: true)
        } else {
            let createMail = configureMail()
            
            if MFMailComposeViewController.canSendMail() {  // Ob man mit dem Handy Mails direkt senden kann
                self.present(createMail, animated: true, completion: nil)
            } else {
                EmailAlert()
                setFirebaseData()
            }
        }
        
        
    }
    
    func setFirebaseData() {
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection("jobOffers")
        } else {
            collectionRef = db.collection("JobOffers")
        }
        let jobRef = collectionRef.document(jobOffer.documentID)
        
        var dataDictionary: [String: Any] = ["name": userName, "userUID": userUID, "qualifications": qualificationTextField.text, "sharedLink": linkTextField.text, "residence" : residenceTextField.text, "motivation" : inputTextField.text, "contact": contactTextField.text, "applicationCreateTime": Timestamp(date: Date()), "message": messageTextField.text]
        
        jobRef.collection("supporter").addDocument(data: dataDictionary)
        
        let newSupporter = jobOffer.interested+1
        jobOffer.interested = newSupporter
        
        jobRef.updateData(["interestedInJob": newSupporter]) { err in
            if let err = err {
                print("Error updating document: \(err.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getUser() {
        if let user = Auth.auth().currentUser {
            if let name = user.displayName {
                self.userName = name
            }
            userUID = user.uid
        }
    }
    
    func configureMail() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["malte.schoppe@gmail.com"])
        mailComposerVC.setSubject("A helping hand!")
        
        let qualification:String = qualificationTextField.text ?? ""
        let residence:String = residenceTextField.text ?? ""
        let input:String = inputTextField.text ?? ""
        let contact:String = contactTextField.text ?? ""
        let link:String = linkTextField.text ?? ""
        let message:String = messageTextField.text ?? ""
        
        mailComposerVC.setMessageBody("Hey Imagine-Team! \n\n My name is \(userName) and I offer my help \(jobTitle). \n I have the following qualifications: \(qualification). \n My home is in: \(residence). \n What I plan to contribute: \(input). \n You can reach me at: \(contact).\n Any messages or links: \(link) \n \(message) \n \n Thank you for your interest!\n We will get in contact with you! \n Have a nice day :) \n \n (And don't worry, if the sentences sound strange)", isHTML: false)
        
        return mailComposerVC
    }
    
    func EmailAlert() {
        let emailError = UIAlertController(title: "We couldnt send the Email!", message: "Check your preferences, if you are locked into your Email at your phone. Your request is saved and the admins alerted, if you want to send this Email anyway please try again or write us at: malte.schoppe@gmail.com", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
            emailError.dismiss(animated: true, completion: nil)
        }
        
        emailError.addAction(action)
        self.present(emailError, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Mail Cancelled")
        case MFMailComposeResult.saved.rawValue:
            print("Mail Saved")
        case MFMailComposeResult.sent.rawValue:
            send = true
            setFirebaseData()
            print("Mail Sent")
        case MFMailComposeResult.failed.rawValue:
            print("Mail sent failure: %@", [error?.localizedDescription])
        default:
            break
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {    // Um zu bestätigen dass die Mail gesendet wurde
        if send {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            let emailSendAlert = UIAlertController(title: NSLocalizedString("thanks", comment: ""), message: NSLocalizedString("jobSurvey_alert_success", comment: ""), preferredStyle: .alert)
            let action1 = UIAlertAction(title: "OK!", style: .default) { (action:UIAlertAction) in
                self.send = false
                emailSendAlert.dismiss(animated: true, completion: nil)
                print("You've pressed OK")
            }
            emailSendAlert.addAction(action1)
            self.present(emailSendAlert, animated: true, completion: nil)
        }
    }
    
}
