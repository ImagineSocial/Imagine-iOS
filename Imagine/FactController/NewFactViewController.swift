//
//  NewFactViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class NewFactViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var sourceTextField: UITextField!
    @IBOutlet weak var ProContraLabel: UILabel!
    @IBOutlet weak var sendButton: DesignableButton!
    
    var fact = Fact()
    var proOrContra = "pro"
    var source = ""
    var new = ""
    var deepArgument = Argument()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        ProContraLabel.text = proOrContra
        ProContraLabel.textColor = .green
        
        
        print("Das ist die ID des Faktes: \(fact.documentID)")
        // Do any additional setup after loading the view.
    }
    
    func setUI() {
        switch new {
        case "deepArgument":
            headerLabel.text = "Teile dein Argument mit uns!"
        case "argument":
            headerLabel.text = "Teile dein Argument mit uns!"
        case "source":
            titleTextField.placeholder = "Nicht nötig"
            descriptionTextField.placeholder = "Nicht nötig"
            headerLabel.text = "Teile deine Quelle mit uns!"
        default:
            headerLabel.text = "Teile deine Weisheit mit uns!"
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descriptionTextField.resignFirstResponder()
        sourceTextField.resignFirstResponder()
    }
    
    @IBAction func contraButtonTapped(_ sender: Any) {
        proOrContra = "contra"
        ProContraLabel.text = proOrContra
        ProContraLabel.textColor = .red
    }
    
    @IBAction func proButtonTapped(_ sender: Any) {
        proOrContra = "pro"
        ProContraLabel.text = proOrContra
        ProContraLabel.textColor = .green
    }
    
   
    @IBAction func sendButtonTapped(_ sender: Any) {
        
        if titleTextField.text != nil && descriptionTextField.text != nil {
            let factRef = Firestore.firestore().collection("Facts").document(fact.documentID).collection("arguments")
            
            let factRefDocumentID = factRef.document().documentID
            source = sourceTextField.text ?? ""
            
            var dataDictionary: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextField.text, "source": source, "documentID": factRefDocumentID, "proOrContra": proOrContra ]

            factRef.document(factRefDocumentID).setData(dataDictionary)
            
            
            let alert = UIAlertController(title: "Fertig!", message: "Danke, dass du hilfst die Seite zu einer besseren zu machen!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                
            }))
            present(alert, animated: true) {
                self.titleTextField.text?.removeAll()
                self.descriptionTextField.text?.removeAll()
                self.sourceTextField.text?.removeAll()
                
            }
        }
        
    }
}
