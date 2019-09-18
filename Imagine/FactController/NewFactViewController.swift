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

enum NewFactType {
    case fact
    case argument
    case deepArgument
    case source
}

enum ArgumentType {
    case pro
    case contra
}

class NewFactViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var sourceTextField: UITextField!
    @IBOutlet weak var ProContraLabel: UILabel!
    @IBOutlet weak var contraButton: DesignableButton!
    @IBOutlet weak var proButton: DesignableButton!
    @IBOutlet weak var addSourceLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    
    var fact: Fact?
    var argument: Argument?
    var proOrContra:ArgumentType = .pro
    var new: NewFactType = .argument
    var deepArgument: Argument?
    
    let db = Firestore.firestore()
    
    var up = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSourceLabel.isHidden = true
        proButton.isHidden = true
        contraButton.isHidden = true
        ProContraLabel.isHidden = true
        sourceTextField.isHidden = true
        
        descriptionTextView.layer.cornerRadius = 3
        descriptionTextView.backgroundColor = Constants.backgroundColorForTableViews

        setUI()
        
        ProContraLabel.text = getProOrContraString()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    
    func setUI() {
        switch new {
        case .deepArgument:
            headerLabel.text = "Teile dein Argument mit uns!"
            addSourceLabel.isHidden = false
        case .argument:
            proButton.isHidden = false
            contraButton.isHidden = false
            ProContraLabel.isHidden = false
            
            headerLabel.text = "Teile dein Argument mit uns!"
            addSourceLabel.isHidden = false
        case .source:
            sourceTextField.isHidden = false
            headerLabel.text = "Teile deine Quelle mit uns!"
        case .fact:
            sourceLabel.isHidden = true
            headerLabel.text = "Erstelle einen neuen Fakt"
        }
    }
    
    // MARK: - Move The Keyboard Up!
    @objc func keyboardWillChange(notification: NSNotification) {
        if self.up == false {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                if sourceTextField.isFirstResponder {
                    self.view.frame.origin.y -= 75
                    self.up = true
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if self.up {
            self.view.frame.origin.y += 75
            self.up = false
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
        sourceTextField.resignFirstResponder()
    }
    
    @IBAction func contraButtonTapped(_ sender: Any) {
        proOrContra = .contra
        ProContraLabel.text = getProOrContraString()
        ProContraLabel.textColor = Constants.red
    }
    
    @IBAction func proButtonTapped(_ sender: Any) {
        proOrContra = .pro
        ProContraLabel.text = getProOrContraString()
        ProContraLabel.textColor = Constants.green
    }
    
    func getProOrContraString() -> String {
        switch proOrContra {
        case .contra:
            return "contra"
        case .pro:
            return "pro"
        }
    }
    
    
    func createNewSource() {
        if let fact = fact, let argument = argument {   // Only possible to add source to specific argument
            let argumentRef = db.collection("Facts").document(fact.documentID).collection("arguments").document(argument.documentID).collection("sources")
            
            let op = Auth.auth().currentUser!
            
            let data: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextView.text, "source": sourceTextField.text, "OP": op.uid]
            
            argumentRef.addDocument(data: data, completion: { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.finished()
                }
            })
        }
    }
    
    func createNewDeepArgument() {
        if let fact = fact, let argument = argument {
            let ref = db.collection("Facts").document(fact.documentID).collection("arguments").document(argument.documentID)
            let op = Auth.auth().currentUser!
            
            let data: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextView.text, "OP": op.uid]
            
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.finished()
                }
            }
        } else {
            self.alert(message: "Es ist ein Fehler aufgetreten. Bitte Versuche es später noch einmal!", title: "Hmm...")
        }
    }
    
    func createNewArgument() {
        if let fact = fact {
            let ref = db.collection("Facts").document(fact.documentID).collection("arguments")
            
            let op = Auth.auth().currentUser!
            
            let data: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextView.text, "proOrContra": getProOrContraString(), "OP": op.uid, "upvotes": 0, "downvotes": 0]
            
            ref.addDocument(data: data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.finished()
                }
            }
        } else {
            self.alert(message: "Es ist ein Fehler aufgetreten. Bitte Versuche es später noch einmal!", title: "Hmm...")
        }
    }
    
    func createNewFact() {
        let ref = db.collection("Facts").document()
        
        let op = Auth.auth().currentUser!
        
        let data: [String: Any] = ["name": titleTextField.text, "description": descriptionTextView.text, "createDate": Timestamp(date: Date()), "OP": op.uid]
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.finished()
            }
        }
    }
    
    func finished() {
        self.alert(message: "Danke für deine Unterstützung", title: "Fertig")
        
        self.titleTextField.text?.removeAll()
        self.descriptionTextView.text?.removeAll()
        self.sourceTextField.text?.removeAll()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func postNewFact(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            if titleTextField.text != "" && descriptionTextView.text != "" {
                switch new {
                case .argument:
                    createNewArgument()
                case .deepArgument:
                    createNewDeepArgument()
                case .fact:
                    createNewFact()
                case .source:
                    createNewSource()
                }
            }
        }
    }
    @IBAction func infoButtonTapped(_ sender: Any) {
    }
}
