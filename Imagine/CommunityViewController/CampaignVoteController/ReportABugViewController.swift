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

enum BugType {
    case bug
    case language
}

class ReportABugViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var reportDescriptionTextView: UITextView!
    
    var type: BugType = .bug
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reportDescriptionTextView.delegate = self
        reportDescriptionTextView.textColor = .lightGray
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.textColor == UIColor.lightGray {
            textView.textColor = UIColor.black
            textView.text = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportDescriptionTextView.resignFirstResponder()
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
        }
    }
    
    func sendBug() {
        if reportDescriptionTextView.text != "" {
            saveReport()
            self.view.activityStartAnimating()
        } else {
            self.alert(message: "Ein bisschen genauer bitte")
        }
    }
    
    func saveReport() {
        if let user = Auth.auth().currentUser {
            let data: [String: Any] = ["userID": user.uid, "bugType": getTypeString(), "problem": reportDescriptionTextView.text]
            
            let bugRef = db.collection("Bugs").document()
            bugRef.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.view.activityStopAnimating()
                    
                    let alert = UIAlertController(title: "Vielen Dank!", message: "Nett, dass du uns unterstützt! Wir versuchen das Netzwerk durchgehend zu verbessern.", preferredStyle: .alert)
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
        doneButton.showEasyTipView(text: Constants.texts.reportBugText)
    }
    
}
