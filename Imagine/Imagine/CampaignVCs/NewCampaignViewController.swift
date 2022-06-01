//
//  NewCampaignViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 18.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import EasyTipView

enum CampaignType {
    case all
    case feature
    case proposal
    case complaint
    case call
    case change
    case topicAddOn
}

class NewCampaignViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var shortBodyTextField: UITextView!
    @IBOutlet weak var longBodyTextField: UITextView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var categoryPickerView: UIPickerView!
    
    var up = false
    let categories: [CampaignCategory] = [CampaignCategory(title: NSLocalizedString("campaign_category_feature", comment: ""), type: .feature), CampaignCategory(title: NSLocalizedString("campaign_category_proposal", comment: "proposal"), type: .proposal), CampaignCategory(title: NSLocalizedString("campaign_category_complaint", comment: "complaint"), type: .complaint), CampaignCategory(title: NSLocalizedString("campaign_category_call", comment: "call for action"), type: .call), CampaignCategory(title: NSLocalizedString("campaign_category_change", comment: "change"), type: .change), CampaignCategory(title: NSLocalizedString("campaign_category_addOn", comment: "comm addOn"), type: .topicAddOn)]
    var chosenCategory: CampaignType = .proposal
    
    var tipView: EasyTipView?
    let db = FirestoreRequest.shared.db
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        shortBodyTextField.resignFirstResponder()
        longBodyTextField.resignFirstResponder()
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    @objc func keyboardWillHide() {
        if up {
            self.view.frame.origin.y += 150
            self.up = false
        }
    }
    
    
    func getCategoryString() -> String {
        switch self.chosenCategory {
        case .feature:
            return "feature"
        case .proposal:
            return "proposal"
        case .complaint:
            return "complaint"
        case .call:
            return "call"
        case .change:
            return "change"
        case .topicAddOn:
            return "topicAddOn"
        case .all:
            return "proposal"
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        if let title = titleTextField.text, let summary = shortBodyTextField.text {
            var collectionRef: CollectionReference!
            let language = LanguageSelection().getLanguage()
            if language == .english {
                collectionRef = db.collection("Data").document("en").collection("campaigns")
            } else {
                collectionRef = db.collection("Campaigns")
            }
            let campaignRef = collectionRef.document()
            
            let dataDictionary: [String: Any] = ["title": title, "summary": summary, "type" : "normal", "category" : getCategoryString(), "description": longBodyTextField.text, "createTime": Timestamp(date: Date()), "supporter": 0, "opposition": 0, "voters": [""]]
            
            campaignRef.setData(dataDictionary) { (err) in
                if let error = err {
                    print("We have an error.: \(error.localizedDescription)")
                } else {
                    print("Successfully added campaign")
                }
            }
            
            let alert = UIAlertController(title: NSLocalizedString("done", comment: "done"), message: NSLocalizedString("submit_successfull_alert_message", comment: "thanks"), preferredStyle: .alert)
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
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.postCampaignText)
            tipView!.show(forItem: doneButton)
        }
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
