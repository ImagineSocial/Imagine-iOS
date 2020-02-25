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
import EasyTipView

enum CampaignType {
    case proposal
    case complaint
    case call
    case change
}

class NewCampaignViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var shortBodyTextField: UITextView!
    @IBOutlet weak var longBodyTextField: UITextView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    
    var up = false
    let categories: [CampaignCategory] = [CampaignCategory(title: "Vorschlag", type: .proposal), CampaignCategory(title: "Beschwerde", type: .complaint), CampaignCategory(title: "Aufruf", type: .call), CampaignCategory(title: "Veränderung", type: .change)]
    var chosenCategory: CampaignType = .proposal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
        categoryPickerView.showsSelectionIndicator = false
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        shortBodyTextField.resignFirstResponder()
        longBodyTextField.resignFirstResponder()
    }
    
    func getDate() -> Timestamp {
        
        return Timestamp(date: Date())
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
    
    
    func getCategoryString() -> String {
        switch self.chosenCategory {
        case .proposal:
            return "proposal"
        case .complaint:
            return "complaint"
        case .call:
            return "call"
        case .change:
            return "change"
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        if titleTextField.text != nil && shortBodyTextField.text != nil {
            let campaignRef = Firestore.firestore().collection("Campaigns")
            
            let campaignRefDocumentID = campaignRef.document().documentID
            var dataDictionary: [String: Any] = ["campaignTitle": titleTextField.text, "campaignShortBody": shortBodyTextField.text, "campaignType" : "normal", "category" : getCategoryString(), "campaignExplanation": longBodyTextField.text, "campaignID": campaignRefDocumentID, "campaignCreateTime": getDate(), "campaignSupporter": 0, "campaignOpposition": 0, "voters": [""]]
            
            campaignRef.document(campaignRefDocumentID).setData(dataDictionary) // Glaube macht keinen Unterschied
            
            
            
            let alert = UIAlertController(title: "Fertig!", message: "Danke, dass du hilfst die Seite zu einer besseren zu machen!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
            }))
            present(alert, animated: true) {
                self.titleTextField.text?.removeAll()
                self.shortBodyTextField.text?.removeAll()
                self.longBodyTextField.text?.removeAll()
            }
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true
            , completion: nil)
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        doneButton.showEasyTipView(text: Constants.texts.postCampaignText)
    }
}

extension NewCampaignViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let category = categories[row]
        
        self.chosenCategory = category.type
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categories[row].title
    }
    
}
