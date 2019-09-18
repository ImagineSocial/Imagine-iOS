//
//  NewCampaignViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 18.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class NewCampaignViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var shortBodyTextField: UITextView!
    @IBOutlet weak var longBodyTextField: UITextView!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var shareButton: DesignableButton!
    
    var up = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        shortBodyTextField.resignFirstResponder()
        longBodyTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
    }
    
    func getDate() -> Timestamp {
        
        return Timestamp(date: Date())
    }
    
    @objc func keyboardWillChange(notification: NSNotification) {
        
        if self.up == false {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if categoryTextField.isFirstResponder {
                    self.view.frame.origin.y -= 150
                    self.up = true
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if up {
            self.view.frame.origin.y += 150
            self.up = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        if titleTextField.text != nil && shortBodyTextField.text != nil {
            let campaignRef = Firestore.firestore().collection("Campaigns")
            
            let campaignRefDocumentID = campaignRef.document().documentID
            var dataDictionary: [String: Any] = ["campaignTitle": titleTextField.text, "campaignShortBody": shortBodyTextField.text, "campaignType" : "normal", "category" : categoryTextField.text, "campaignExplanation": longBodyTextField.text, "campaignID": campaignRefDocumentID, "campaignCreateTime": getDate(), "campaignSupporter": 0, "campaignOpposition": 0, "voters": [""]]
            
            
            
            
            campaignRef.document(campaignRefDocumentID).setData(dataDictionary) // Glaube macht keinen Unterschied
            
            
            
            let alert = UIAlertController(title: "Fertig!", message: "Danke, dass du hilfst die Seite zu einer besseren zu machen!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
            }))
            present(alert, animated: true) {
                self.titleTextField.text?.removeAll()
                self.shortBodyTextField.text?.removeAll()
                self.longBodyTextField.text?.removeAll()
                self.categoryTextField.text?.removeAll()
            }
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true
            , completion: nil)
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
    }
}
