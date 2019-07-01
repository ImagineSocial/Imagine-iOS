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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.title = "Erstelle eine neue Kampagne"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        shortBodyTextField.resignFirstResponder()
        longBodyTextField.resignFirstResponder()
        categoryTextField.resignFirstResponder()
    }
    
    func getDate() -> Timestamp {
        
        let formatter = DateFormatter()
        let date = Date()
        
        formatter.dateFormat = "dd MM yyyy HH:mm"
        
        let stringDate = formatter.string(from: date)
        
        if let result = formatter.date(from: stringDate) {
            
            let dateTimestamp :Timestamp = Timestamp(date: result)  // Hat keine Nanoseconds
            
            return dateTimestamp
        }
        return Timestamp(date: date)
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        if titleTextField.text != nil && shortBodyTextField.text != nil {
            let campaignRef = Firestore.firestore().collection("Campaigns")
            
            let campaignRefDocumentID = campaignRef.document().documentID
            var dataDictionary: [String: Any] = ["campaignTitle": titleTextField.text, "campaignShortBody": shortBodyTextField.text, "campaignType" : "normal", "campaignCategory" : categoryTextField.text, "campaignExplanation": longBodyTextField.text, "campaignID": campaignRefDocumentID, "campaignCreateTime": getDate(), "campaignSupporter": 0, "campaignOpposition": 0]
            
            
            
            
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
    
}
