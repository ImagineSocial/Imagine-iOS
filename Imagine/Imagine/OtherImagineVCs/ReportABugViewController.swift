//
//  ReportABugViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 02.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import EasyTipView

enum BugType {
    case bug
    case language
    case feedback
}

class ReportABugViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var reportDescriptionTextView: UITextView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subHeaderLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var type: BugType = .bug
    let db = FirestoreRequest.shared.db
    
    var tipView: EasyTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reportDescriptionTextView.delegate = self
        
        if type == .feedback {
            subHeaderLabel.text = "Feedback:"
            headerLabel.text = NSLocalizedString("reportABug_header", comment: "any feedback is appreciated")
            descriptionLabel.text = NSLocalizedString("reportABug_description", comment: "whatever")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.textColor == UIColor.lightGray {
            textView.textColor = UIColor.black
            textView.text = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportDescriptionTextView.resignFirstResponder()
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        reportDescriptionTextView.resignFirstResponder()
        sendBug()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        reportDescriptionTextView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    func getTypeString() -> String {
        switch type {
        case .bug:
            return "bug"
        case .language:
            return "language"
        case .feedback:
            return "feedback"
        }
    }
    
    func sendBug() {
        if reportDescriptionTextView.text != "" {
            saveReport()
            self.view.activityStartAnimating()
        } else {
            self.alert(message: NSLocalizedString("more_information_alert", comment: "give more info"))
        }
    }
    
    func saveReport() {
        
        if let text = reportDescriptionTextView.text {
            
            let maltesUID = "CZOcL3VIwMemWwEfutKXGAfdlLy1"
            
            var userID = ""
            if let user = Auth.auth().currentUser {
                userID = user.uid
            }
            
            let notificationRef = db.collection("Users").document(maltesUID).collection("notifications").document()
            let notificationData: [String: Any] = ["type": "message", "message": "Ein neuer Bug: \(String(describing: text))", "name": "System", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "UserID": userID]
            
            notificationRef.setData(notificationData) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Successfully set notification")
                }
            }
            
            let data: [String: Any] = ["userID": userID, "bugType": getTypeString(), "problem": text]
            
            let bugRef = db.collection("Feedback").document("bugs").collection("bugs").document()
            
            bugRef.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                    
                    let alert = UIAlertController(title: NSLocalizedString("thanks", comment: "thanks"), message: NSLocalizedString("thanks_alert_message", comment: "thanks for sharing"), preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        self.reportDescriptionTextView.text.removeAll()
                        
                        self.dismiss(animated: true, completion: nil)
                        alert.dismiss(animated: true, completion: {
                            
                        })
                    })
                    alert.addAction(ok)
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.reportBugText)
            tipView!.show(forItem: doneButton)
        }
    }
    
}
