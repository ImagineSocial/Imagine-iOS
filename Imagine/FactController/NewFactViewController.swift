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
import FirebaseAuth
import EasyTipView

enum NewFactType {
    case fact
    case argument
    case deepArgument
    case source
    case addOn
    case addOnHeader
}

enum ArgumentType {
    case pro
    case contra
}

enum FactDisplayName {
    case proContra
    case confirmDoubt
    case advantageDisadvantage
}

enum DisplayOption {
    case fact
    case topic
}

protocol NewFactDelegate {
    func finishedCreatingNewInstance(item: Any?)
}

class NewFactViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var sourceTextField: UITextField!
    @IBOutlet weak var ProContraLabel: UILabel!
    @IBOutlet weak var addSourceLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextView!
    @IBOutlet weak var proContraSegmentedControl: UISegmentedControl!
    @IBOutlet weak var seperatorView3: UIView!
    @IBOutlet weak var titleCharacterCountLabel: UILabel!
    @IBOutlet weak var descriptionCharacterCountLabel: UILabel!
    
    var fact: Fact?
    var argument: Argument?
    var proOrContra:ArgumentType = .pro
    var new: NewFactType = .argument
    var deepArgument: Argument?
    
    var tipView: EasyTipView?
    
    let db = Firestore.firestore()
    
    var up = false
    
    let pickerOptions = ["Contra/Pro", "Zweifel/Bestätigung", "Nachteile/Vorteile"]
    let factDescription = "Das Thema wird in zwei Spalten dargestellt. Die Gegenüberstellung ermöglicht es sich mit dem Thema gründlich auseinanderzusetzen. \nDie Auswahl der Überschriften der Spalten kannst du hier auswählen:"
    let topicDescripton = "Das Thema wird als Sammlung aller verlinkten Beiträge zu diesem Thema dargestellt."
    
    let factTitleCharacterLimit = 30
    let factDescriptionCharacterLimit = 120
    
    let argumentTitleCharacterLimit = 85
    
    let sourceTitleCharacterLimit = 50
    
    let addOnTitleCharacterLimit = 50
    let addOnDescriptionCharacterLimit = 300
    
    let addOnHeaderTitleCharacterLimit = 50
    let addOnHeaderDescriptionCharacterLimit = 400
    
    var pickedFactDisplayNames: FactDisplayName = .proContra
    var pickedDisplayOption: DisplayOption = .fact
    
    var delegate: NewFactDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleTextField.delegate = self
        descriptionTextView.delegate = self
        
        newFactDisplayPicker.delegate = self
        newFactDisplayPicker.dataSource = self
        
        addSourceLabel.isHidden = true
        proContraSegmentedControl.isHidden = true
        ProContraLabel.isHidden = true
        sourceTextField.isHidden = true
        
        
        descriptionTextView.layer.cornerRadius = 3

        setUI()
                
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK:- Setup
    
    func setUI() {
        switch new {
        case .deepArgument:
            headerLabel.text = "Teile dein Argument mit uns!"
            addSourceLabel.isHidden = true
            sourceLabel.isHidden = true
            seperatorView3.isHidden = true
            
            
            titleCharacterCountLabel.text = String(argumentTitleCharacterLimit)
        case .argument:
            titleCharacterCountLabel.text = String(argumentTitleCharacterLimit)
            
            if let fact = fact {
                switch fact.factDisplayNames {
                case .advantageDisadvantage:
                    proContraSegmentedControl.setTitle("Vorteile", forSegmentAt: 0)
                    proContraSegmentedControl.setTitle("Nachteile", forSegmentAt: 1)
                case .confirmDoubt:
                    proContraSegmentedControl.setTitle("Zweifel", forSegmentAt: 0)
                    proContraSegmentedControl.setTitle("Bestätigung", forSegmentAt: 1)
                default:
                    print("Stays pro/contra")
                }
            }
            
            switch proOrContra {
            case .contra:
                proContraSegmentedControl.selectedSegmentIndex = 0
            default:
                proContraSegmentedControl.selectedSegmentIndex = 1
            }
            
            proContraSegmentedControl.isHidden = false
            ProContraLabel.isHidden = false
            
            headerLabel.text = "Teile dein Argument mit uns!"
            addSourceLabel.isHidden = false
            sourceLabel.isHidden = true
        case .source:
            titleCharacterCountLabel.text = String(sourceTitleCharacterLimit)
            
            sourceTextField.isHidden = false
            headerLabel.text = "Teile deine Quelle mit uns!"
        case .fact:
            titleCharacterCountLabel.text = String(factTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(factDescriptionCharacterLimit)
            
            descriptionCharacterCountLabel.isHidden = false
            seperatorView3.isHidden = true
            sourceLabel.isHidden = true
            headerLabel.text = "Erstelle einen neuen Fakt"
            descriptionLabel.text = factDescription
            
            setNewFactDisplayOptions()
        case .addOn:
            titleCharacterCountLabel.text = String(addOnTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(addOnDescriptionCharacterLimit)
            
            headerLabel.text = "Teile ein neues AddOn mit deinen Mitmenschen!"
            addSourceLabel.isHidden = true
            sourceLabel.isHidden = true
            seperatorView3.isHidden = true
            descriptionCharacterCountLabel.isHidden = false
        case .addOnHeader:
            titleCharacterCountLabel.text = String(addOnHeaderTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(addOnHeaderDescriptionCharacterLimit)
            
            headerLabel.text = "Teile einen neuen Header mit deinen Mitmenschen!"
            sourceLabel.text = "Link zu mehr Informationen (optional):"
            titleLabel.text = "Kurzes Intro:"
            sourceTextField.isHidden = false
            descriptionCharacterCountLabel.isHidden = false
        }
    }
    
    
    
    //MARK:-
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
        sourceTextField.resignFirstResponder()
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    @objc func segmentChanged() {
        
        switch newTopicDisplayTypeSelection.selectedSegmentIndex {
        case 0:
            // Fact
            self.pickedDisplayOption = .fact
            
            UIView.animate(withDuration: 0.3, animations: {
                self.newFactDisplayPicker.alpha = 1
                
            }) { (_) in
                
            }
            descriptionLabel.fadeTransition(0.3)
            descriptionLabel.text = factDescription
            descriptionImageView.image = UIImage(named: "FactDisplay")
        case 1:
            // Topic
            self.pickedDisplayOption = .topic
            
            UIView.animate(withDuration: 0.3, animations: {
                self.newFactDisplayPicker.alpha = 0
                
            }) { (_) in
                
            }
            descriptionLabel.fadeTransition(0.3)
            descriptionLabel.text = topicDescripton
            descriptionImageView.image = UIImage(named: "TopicDisplay")
        default:
            print("Wont happen")
        }
    }
    
    
    func getProOrContraString() -> String {
        switch proOrContra {
        case .contra:
            return "contra"
        case .pro:
            return "pro"
        }
    }
    
    func getNewFactDisplayString(displayOption: DisplayOption) -> (displayOption: String, factDisplayNames: String?) {
        switch displayOption {
            case .fact:
                switch self.pickedFactDisplayNames {
                case .proContra:
                    return (displayOption: "fact", factDisplayNames: "proContra")
                case .confirmDoubt:
                    return (displayOption: "fact", factDisplayNames: "confirmDoubt")
                case .advantageDisadvantage:
                    return (displayOption: "fact", factDisplayNames: "advantage")
                }
            case .topic:
                return (displayOption: "topic", factDisplayNames: nil)
        }
    }
    
    //MARK: - Create Data
    
    func createNewInstance() {
        switch new {
        case .argument:
            createNewArgument()
        case .deepArgument:
            createNewDeepArgument()
        case .fact:
            createNewFact()
        case .source:
            createNewSource()
        case .addOn:
            createNewAddOn()
        case.addOnHeader:
            createNewAddOnHeader()
        }
    }
    
    func createNewAddOnHeader() {
        
        if let fact = fact {
            let ref = db.collection("Facts").document(fact.documentID).collection("addOns")
            
            let op = Auth.auth().currentUser!
            
            var data: [String: Any] = ["OP": op.uid, "headerDescription": descriptionTextView.text]
            
            if sourceTextField.text != "" {
                data["moreInformationLink"] = sourceTextField.text
            }
            if titleTextField.text != "" {
                data["headerIntro"] = titleTextField.text
            }
            
            ref.addDocument(data: data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.finished(item: nil)// Will reload the database in the delegate
                }
            }
        }
    }
    
    func createNewAddOn() {
        
        if let fact = fact {
            let ref = db.collection("Facts").document(fact.documentID).collection("addOns")
            
            let op = Auth.auth().currentUser!
            
            let data: [String: Any] = ["OP": op.uid, "title": titleTextField.text, "description": descriptionTextView.text]
            
            ref.addDocument(data: data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.finished(item: nil)// Will reload the database in the delegate
                }
            }
        }
    }
    
    func createNewSource() {
        if let fact = fact, let argument = argument {   // Only possible to add source to specific argument
            let argumentRef = db.collection("Facts").document(fact.documentID).collection("arguments").document(argument.documentID).collection("sources").document()
            
            let op = Auth.auth().currentUser!
            
            let data: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextView.text, "source": sourceTextField.text, "OP": op.uid]
            
            argumentRef.setData(data, completion: { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    let source = Source(addMoreDataCell: false)
                    source.title = self.titleTextField.text
                    source.description = self.descriptionTextView.text
                    source.source = self.sourceTextField.text!
                    source.documentID = argumentRef.documentID
                    
                    self.finished(item: source)
                }
            })
        }
    }
    
    func createNewDeepArgument() {
        if let fact = fact, let argument = argument {
            let ref = db.collection("Facts").document(fact.documentID).collection("arguments").document(argument.documentID).collection("arguments").document()
            let op = Auth.auth().currentUser!
            
            let data: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextView.text, "OP": op.uid]
            
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    let argument = Argument(addMoreDataCell: false)
                    argument.title  = self.titleTextField.text
                    argument.description = self.descriptionTextView.text
                    argument.documentID = ref.documentID
                    
                    self.finished(item: argument)
                }
            }
        } else {
            self.alert(message: "Es ist ein Fehler aufgetreten. Bitte Versuche es später noch einmal!", title: "Hmm...")
        }
    }
    
    func createNewArgument() {
        if let fact = fact {
            let ref = db.collection("Facts").document(fact.documentID).collection("arguments").document()
            
            let op = Auth.auth().currentUser!
            let proOrContra = getProOrContraString()
            
            let data: [String:Any] = ["title" : titleTextField.text, "description": descriptionTextView.text, "proOrContra": proOrContra, "OP": op.uid, "upvotes": 0, "downvotes": 0]
            
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    let argument = Argument(addMoreDataCell: false)
                    argument.title  = self.titleTextField.text
                    argument.description = self.descriptionTextView.text
                    argument.proOrContra = proOrContra
                    argument.documentID = ref.documentID
                    
                    self.finished(item: argument)
                }
            }
        } else {
            self.alert(message: "Es ist ein Fehler aufgetreten. Bitte Versuche es später noch einmal!", title: "Hmm...")
        }
    }
    
    func createNewFact() {
        let ref = db.collection("Facts").document()
        
        let op = Auth.auth().currentUser!
        
        let displayOption = self.getNewFactDisplayString(displayOption: self.pickedDisplayOption)
        
        var data = [String: Any]()
        
        if let factDisplayName = displayOption.factDisplayNames {
            data = ["name": titleTextField.text, "description": descriptionTextView.text, "createDate": Timestamp(date: Date()), "OP": op.uid, "displayOption": displayOption.displayOption, "factDisplayNames": factDisplayName, "popularity": 0]
        } else {
            data = ["name": titleTextField.text, "description": descriptionTextView.text, "createDate": Timestamp(date: Date()), "OP": op.uid, "displayOption": displayOption.displayOption, "popularity": 0]
        }
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                
                self.finished(item: nil)    // Will reload the database in the delegate
            }
        }
    }
    
    func finished(item: Any?) {
        let alertController = UIAlertController(title: "Vielen Dank", message: "Deine Eingabe wurde erfolgreich hinzugefügt!", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            self.dismiss(animated: true) {
                self.delegate?.finishedCreatingNewInstance(item: item)
            }
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
        
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
    
    //MARK:- Buttons
    @IBAction func postNewFact(_ sender: Any) {
        
        if let _ = Auth.auth().currentUser {
            if titleTextField.text != "" && descriptionTextView.text != "" {
                self.createNewInstance()
            } else {
                self.alert(message: "Gib bitte einen Titel und eine Beschreibung ein", title: "Wir brauchen mehr Informationen")
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func proContraSegmentChanged(_ sender: Any) {
        
        if proContraSegmentedControl.selectedSegmentIndex == 0 {
            proOrContra = .pro
        } else {
            proOrContra = .contra
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

    @IBAction func infoButtonTapped(_ sender: Any) {
        tipView = EasyTipView(text: Constants.texts.addArgumentText)
        tipView!.show(forItem: doneButton)
    }
    
    //MARK:- UI
    
    func setNewFactDisplayOptions() {
        self.view.addSubview(newTopicDisplayTypeSelection)
        newTopicDisplayTypeSelection.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        newTopicDisplayTypeSelection.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        newTopicDisplayTypeSelection.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 10).isActive = true
        newTopicDisplayTypeSelection.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        self.view.addSubview(descriptionImageView)
        descriptionImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        descriptionImageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        descriptionImageView.topAnchor.constraint(equalTo: newTopicDisplayTypeSelection.bottomAnchor, constant: 10).isActive = true
        descriptionImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        self.view.addSubview(descriptionLabel)
        descriptionLabel.leadingAnchor.constraint(equalTo: descriptionImageView.trailingAnchor, constant: 10).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: newTopicDisplayTypeSelection.bottomAnchor, constant: 10).isActive = true
        descriptionLabel.bottomAnchor.constraint(equalTo: descriptionImageView.bottomAnchor).isActive = true
        
        self.view.addSubview(newFactDisplayPicker)
        newFactDisplayPicker.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        newFactDisplayPicker.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        newFactDisplayPicker.topAnchor.constraint(equalTo: descriptionImageView.bottomAnchor, constant: 10).isActive = true
        newFactDisplayPicker.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -25).isActive = true
    }
    
    let newTopicDisplayTypeSelection: UISegmentedControl = {
       let segment = UISegmentedControl()
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.insertSegment(withTitle: "Diskussions-Darstellung", at: 0, animated: false)
        segment.insertSegment(withTitle: "Themen-Darstellung", at: 1, animated: false)
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        return segment
    }()
    
    
    let newFactDisplayPicker: UIPickerView = {
       let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.showsSelectionIndicator = true
        
        return picker
    }()
    
    let descriptionLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }()
    
    let descriptionImageView: UIImageView = {
       let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFit
        imgView.image = UIImage(named: "FactDisplay")
        
        return imgView
    }()
    
}

extension NewFactViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if textView == titleTextField {  // No lineBreaks in titleTextView
            guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
                return descriptionTextView.becomeFirstResponder()   // Switch to description when "continue" is hit on keyboard
            }
            
            switch new { // Title no longer than x characters
            case .fact:
                return textView.text.count + (text.count - range.length) <= factTitleCharacterLimit
            case .addOn:
                return textView.text.count + (text.count - range.length) <= addOnTitleCharacterLimit
            case .addOnHeader:
                return textView.text.count + (text.count - range.length) <= addOnHeaderTitleCharacterLimit
            case .argument:
                return textView.text.count + (text.count - range.length) <= argumentTitleCharacterLimit
            case .deepArgument:
                return textView.text.count + (text.count - range.length) <= argumentTitleCharacterLimit
            case .source:
                return textView.text.count + (text.count - range.length) <= sourceTitleCharacterLimit
            }
            
        } else if textView == descriptionTextView {
            
            switch new { // Title no longer than x characters
            case .fact:
                return textView.text.count + (text.count - range.length) <= factDescriptionCharacterLimit
            case .addOn:
                return textView.text.count + (text.count - range.length) <= addOnDescriptionCharacterLimit
            case .addOnHeader:
                return textView.text.count + (text.count - range.length) <= addOnHeaderDescriptionCharacterLimit
            default:
                print("No Limit")
                return true
            }
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if textView == titleTextField {
            switch new { // Title no longer than x characters
            case .fact:
                let characterLeft = factTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .addOn:
                let characterLeft = addOnTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .addOnHeader:
                let characterLeft = addOnHeaderTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .argument:
                let characterLeft = argumentTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .deepArgument:
                let characterLeft = argumentTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .source:
                let characterLeft = sourceTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            }
        } else {    // DescriptionTextView
            switch new { // Title no longer than x characters
            case .fact:
                let characterLeft = factDescriptionCharacterLimit-textView.text.count
                self.descriptionCharacterCountLabel.text = String(characterLeft)
            case .addOn:
                let characterLeft = addOnDescriptionCharacterLimit-textView.text.count
                self.descriptionCharacterCountLabel.text = String(characterLeft)
            case .addOnHeader:
                let characterLeft = addOnHeaderDescriptionCharacterLimit-textView.text.count
                self.descriptionCharacterCountLabel.text = String(characterLeft)
            default:
                print("No Limit")
                
            }
        }
    }
}

extension NewFactViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            self.pickedFactDisplayNames = .proContra
            
        case 1:
            self.pickedFactDisplayNames = .confirmDoubt
            
        case 2:
            self.pickedFactDisplayNames = .advantageDisadvantage
            
        default:
            print("Wrong row?")
        }
    }
    
    
    
}
