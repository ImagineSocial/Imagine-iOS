//
//  MeldeAgreeViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import Firebase
import FirebaseAuth

class MeldeAgreeViewController: UIViewController {

    var reportCategory: reportCategory?
    var choosenReportOption: ReportOption?
    var post: Post?
    var comment: Comment?
    let db = Firestore.firestore()
    
    @IBOutlet weak var MeldegrundLabel: UILabel!
    @IBOutlet weak var HinweisTextLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        displayNoticeAndWarning()
        
    }
    
    func displayNoticeAndWarning() {
        let text = NSLocalizedString("report_reason_description", comment: "your report:")
        MeldegrundLabel.text = String.localizedStringWithFormat(text, choosenReportOption!.text)
        
        guard let category = self.reportCategory else { return }
        
        switch category {
        case .markVisually:
            HinweisTextLabel.text = NSLocalizedString("report_markVisually_description", comment: "what will happen if i do this?")
        case .violationOfRules:
            HinweisTextLabel.text = NSLocalizedString("report_ruleViolation/content_description", comment: "what will happen if i do this?")
        case .content:
            HinweisTextLabel.text = NSLocalizedString("report_ruleViolation/content_description", comment: "what will happen if i do this?")
        }
    }
    
    func getReportCategoryString(reportCategory: reportCategory) -> String {
        switch reportCategory {
        case .markVisually:
            return "Optisch markieren"
        case .violationOfRules:
            return "Regelverstoß"
        case .content:
            return "Inhalt"
        }
    }
    
    func saveReportOption() {
        
        // Erstmal nur optische Auswahl
        var reportOptionForDatabase = String()
        
        switch choosenReportOption!.reportOption {
        case .personalOpinion:
            reportOptionForDatabase = "opinion"
        case .sensationalism:
            reportOptionForDatabase = "sensationalism"
        case .editedContent:
            reportOptionForDatabase = "edited"
        case .satire:
            reportOptionForDatabase = "satire"
        case .spoiler:
            reportOptionForDatabase = "spoiler"
        case .pornography:
            reportOptionForDatabase = "blocked"
        case .pedophilia:
            reportOptionForDatabase = "blocked"
        case .violence:
            reportOptionForDatabase = "blocked"
        case .racism:
            reportOptionForDatabase = "blocked"
        case .animalCruelty:
            reportOptionForDatabase = "blocked"
        default:
            reportOptionForDatabase = "normal"
        }
        
        if let post = post {
            let postRef = db.collection("Posts")
            postRef.document(post.documentID).updateData(["report": reportOptionForDatabase]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                    
                }
            }
        } else if let comment = comment {
            //todo: Find Comment Ref and update Data
        }
    }
    
    func saveReport() {
        
        if let user = Auth.auth().currentUser {
            
            let notificationRef = db.collection("Users").document("CZOcL3VIwMemWwEfutKXGAfdlLy1").collection("notifications").document()
            let notificationData: [String: Any] = ["type": "message", "message": "Jemand hat eine Sache markiert oder gemeldet", "name": "Meldung", "chatID": "Egal", "sentAt": Timestamp(date: Date()), "messageID": user.uid]
            
            
            notificationRef.setData(notificationData) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Successfully set notification")
                }
            }
            
            if let post = post {
                
                let data: [String:Any] = ["category": getReportCategoryString(reportCategory: reportCategory!), "reason": choosenReportOption!.text, "reportingUser": user.uid, "reported post":post.documentID]
                
                saveReportInDatabase(data: data)
                
            } else if let comment = comment {
                let data: [String:Any] = ["category": getReportCategoryString(reportCategory: reportCategory!), "reason": choosenReportOption!.text, "reportingUser": user.uid, "reported comment": comment.commentID]
                
                saveReportInDatabase(data: data)
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func saveReportInDatabase(data: [String:Any]) {
        
        let ref = db.collection("Reports").document()
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully saved")
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        saveReportOption()
        saveReport()
    }
    
    
}
