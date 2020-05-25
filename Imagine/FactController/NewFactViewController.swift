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
    case singleTopicAddOn
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
    
    var selectedTopicIDForSingleTopicAddOn: String?
    
    var tipView: EasyTipView?
    
    let db = Firestore.firestore()
    
    var up = false
    
    let pickerOptions = ["Contra/Pro", "Zweifel/Bestätigung", "Nachteile/Vorteile"]
    let factDescription = "Das Thema wird in zwei Spalten dargestellt. Die Gegenüberstellung ermöglicht es sich mit dem Thema gründlich auseinanderzusetzen. \nDie Auswahl der Überschriften der Spalten kannst du hier auswählen:"
    let topicDescripton = "Das Thema wird als Sammlung aller verlinkten Beiträge zu diesem Thema dargestellt."
    
    
    
    var pickedFactDisplayNames: FactDisplayName = .proContra
    var pickedDisplayOption: DisplayOption = .fact
    
    var selectedImageFromPicker:UIImage?
    var imagePicker = UIImagePickerController()
    
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
        
        imagePicker.delegate = self
                
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
            
            
            titleCharacterCountLabel.text = String(Constants.characterLimits.argumentTitleCharacterLimit)
        case .argument:
            titleCharacterCountLabel.text = String(Constants.characterLimits.argumentTitleCharacterLimit)
            
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
            titleCharacterCountLabel.text = String(Constants.characterLimits.sourceTitleCharacterLimit)
            
            sourceTextField.isHidden = false
            headerLabel.text = "Teile deine Quelle mit uns!"
        case .fact:
            titleCharacterCountLabel.text = String(Constants.characterLimits.factTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(Constants.characterLimits.factDescriptionCharacterLimit)
            
            descriptionCharacterCountLabel.isHidden = false
            headerLabel.text = "Teile ein neues Thema mit deinen Mitmenschen."
            descriptionLabel.text = factDescription
            
            addSourceLabel.removeFromSuperview()
            sourceLabel.text = "Bild:"
            selectButton.setTitle("", for: .normal)
            selectButton.setImage(UIImage(named: "folder"), for: .normal)
            selectButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
            
            setSelectionTopicAndTopicPictureUI()
            setNewFactDisplayOptions()
        case .addOn:
            titleCharacterCountLabel.text = String(Constants.characterLimits.addOnTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(Constants.characterLimits.addOnDescriptionCharacterLimit)
            
            headerLabel.text = "Teile ein neues AddOn mit deinen Mitmenschen!"
            addSourceLabel.isHidden = true
            sourceLabel.isHidden = true
            seperatorView3.isHidden = true
            descriptionCharacterCountLabel.isHidden = false
        case .addOnHeader:
            titleCharacterCountLabel.text = String(Constants.characterLimits.addOnHeaderTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(Constants.characterLimits.addOnHeaderDescriptionCharacterLimit)
            
            headerLabel.text = "Teile einen neuen Header mit deinen Mitmenschen!"
            sourceLabel.text = "Link zu mehr Informationen (optional):"
            titleLabel.text = "Kurzes Intro: "
            sourceTextField.isHidden = false
            descriptionCharacterCountLabel.isHidden = false
        case .singleTopicAddOn:
            titleCharacterCountLabel.text = String(Constants.characterLimits.addOnTitleCharacterLimit)
            descriptionCharacterCountLabel.text = String(Constants.characterLimits.addOnDescriptionCharacterLimit)
            descriptionCharacterCountLabel.isHidden = false
            
            headerLabel.text = "Teile dein AddOn mit uns!"
            addSourceLabel.removeFromSuperview()
            sourceLabel.text = "Thema:"
            
            self.setSelectionTopicAndTopicPictureUI()
        }
    }
    
    
    
    //MARK:-
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectFactSegue" {
            if let navCon = segue.destination as? UINavigationController {
                if let factVC = navCon.topViewController as? FactCollectionViewController {
                    factVC.addFactToPost = .newPost
                    factVC.delegate = self
                }
            }
        }
    }
    
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
            let ref = db.collection("Facts").document()
            if selectedImageFromPicker != nil {
                if let user = Auth.auth().currentUser {
                    
                    self.savePicture(userID: user.uid, topicRef: ref)
                }
            } else {
                createNewFact(ref: ref, imageURL: nil)
            }
        case .source:
            createNewSource()
        case .addOn:
            createNewAddOn()
        case.addOnHeader:
            createNewAddOnHeader()
        case .singleTopicAddOn:
            createNewSingleTopicAddOn()
        }
    }
    
    func createNewSingleTopicAddOn() {
        
        if let fact = fact {
            if let linkedFactID = self.selectedTopicIDForSingleTopicAddOn {
            let ref = db.collection("Facts").document(fact.documentID).collection("addOns")
            
            let op = Auth.auth().currentUser!
            
                var data: [String: Any] = ["OP": op.uid, "headerTitle": titleTextField.text, "description": descriptionTextView.text, "linkedFactID": linkedFactID, "popularity": 0]
            
            ref.addDocument(data: data) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.finished(item: nil)// Will reload the database in the delegate
                }
            }
            } else {
                self.alert(message: "Wir haben kein Thema zum verlinken registriert!")
            }
        }
    }
    
    func createNewAddOnHeader() {
        
        if let fact = fact {
            let ref = db.collection("Facts").document(fact.documentID).collection("addOns")
            
            let op = Auth.auth().currentUser!
            
            var data: [String: Any] = ["OP": op.uid, "headerDescription": descriptionTextView.text, "popularity": 0]
            
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
            
            let data: [String: Any] = ["OP": op.uid, "title": titleTextField.text, "description": descriptionTextView.text, "popularity": 0]
            
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
    
    func createNewFact(ref: DocumentReference, imageURL: String?) {
        
        let op = Auth.auth().currentUser!
        
        let displayOption = self.getNewFactDisplayString(displayOption: self.pickedDisplayOption)
        
        var data = [String: Any]()
        
        data = ["name": titleTextField.text, "description": descriptionTextView.text, "createDate": Timestamp(date: Date()), "OP": op.uid, "displayOption": displayOption.displayOption, "popularity": 0]
        
        if let factDisplayName = displayOption.factDisplayNames {
            data["factDisplayNames"] = factDisplayName
        }
        
        if let url = imageURL {
            data["imageURL"] = url
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
        self.view.activityStopAnimating()
        let alertController = UIAlertController(title: "Vielen Dank", message: "Deine Eingabe wurde erfolgreich hinzugefügt!", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            self.dismiss(animated: true) {
                self.doneButton.isEnabled = true
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
                self.view.activityStartAnimating()
                self.doneButton.isEnabled = false
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
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            var text = ""
            switch new {
            case .addOnHeader:
                text = Constants.texts.AddOns.headerText
            case .singleTopicAddOn:
                text = Constants.texts.AddOns.singleTopicText
            case .addOn:
                text = Constants.texts.AddOns.collectionText
            case .fact:
                text = "Erstelle eine neue Community oder eine neue Diskussion. \nEin Bild ist dabei optional aber immer gern gesehen\n\nDu bist vorerst der Moderator der von dir erstellten Communities und Diskussionen und kannst zu einem späteren Zeitpunkt die Informationen und Metadaten bearbeiten."
            default:
                text = Constants.texts.addArgumentText
            }
            
            tipView = EasyTipView(text: text)
            tipView!.show(forItem: doneButton)
        }
    }
    
    @objc func selectTopicButtonTapped() {
        if new == .singleTopicAddOn {
            performSegue(withIdentifier: "selectFactSegue", sender: nil)
        } else if new == .fact {
            showImagePicker()
        } else {
            print("Why is a button active here")
        }
    }
    
    func showImagePicker() {
        self.imagePicker.sourceType = .photoLibrary
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    
    //MARK:- UI
    func setSelectionTopicAndTopicPictureUI() { //For a newTopic as a preview of the chosen Picture and for singleTopicAddOn for the selection of a topic to link to
        
        sourceLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true    //FML
        
        self.view.addSubview(topicPicturePreviewImageView)
        topicPicturePreviewImageView.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 5).isActive = true
        topicPicturePreviewImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 25).isActive = true
        if new == .fact {
            topicPicturePreviewImageView.widthAnchor.constraint(equalToConstant: 75).isActive = true
            topicPicturePreviewImageView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        } else {
            topicPicturePreviewImageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
            topicPicturePreviewImageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        }
        topicPicturePreviewImageView.bottomAnchor.constraint(equalTo: seperatorView3.topAnchor, constant: -10).isActive = true
        
        self.view.addSubview(selectButton)
        selectButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        selectButton.topAnchor.constraint(equalTo: topicPicturePreviewImageView.topAnchor, constant: 10).isActive = true
        selectButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        topicPicturePreviewImageView.image = nil
        
        self.view.addSubview(topicPreviewLabel)
        topicPreviewLabel.leadingAnchor.constraint(equalTo: topicPicturePreviewImageView.trailingAnchor, constant: 10).isActive = true
        topicPreviewLabel.centerYAnchor.constraint(equalTo: topicPicturePreviewImageView.centerYAnchor).isActive = true
        topicPreviewLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    func setNewFactDisplayOptions() {   // Selection UI for a new Topic/Community
        self.view.addSubview(newTopicDisplayTypeSelection)
        newTopicDisplayTypeSelection.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        newTopicDisplayTypeSelection.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        newTopicDisplayTypeSelection.topAnchor.constraint(equalTo: seperatorView3.bottomAnchor, constant: 10).isActive = true
        newTopicDisplayTypeSelection.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        if pickedDisplayOption == .fact {
            newTopicDisplayTypeSelection.selectedSegmentIndex = 0
        } else if pickedDisplayOption == .topic {
            newTopicDisplayTypeSelection.selectedSegmentIndex = 1
            self.segmentChanged()
        }
        
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
        newFactDisplayPicker.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    let selectButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Thema auswählen", for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.setTitleColor(.imagineColor, for: .normal)
        button.addTarget(self, action: #selector(selectTopicButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
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
    
    let topicPicturePreviewImageView: UIImageView = {
       let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFill
        imgView.image = UIImage(named: "FactDisplay")
        imgView.layer.cornerRadius = 4
        imgView.clipsToBounds = true
        
        return imgView
    }()
    
    let topicPreviewLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        label.numberOfLines = 0
        label.minimumScaleFactor = 0.3
        label.adjustsFontSizeToFitWidth = true
        
        return label
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
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.factTitleCharacterLimit
            case .addOn:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.addOnTitleCharacterLimit
            case .addOnHeader:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.addOnHeaderTitleCharacterLimit
            case .argument:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.argumentTitleCharacterLimit
            case .deepArgument:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.argumentTitleCharacterLimit
            case .source:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.sourceTitleCharacterLimit
            case .singleTopicAddOn:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.addOnTitleCharacterLimit
            }
            
        } else if textView == descriptionTextView {
            
            switch new { // Title no longer than x characters
            case .fact:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.factDescriptionCharacterLimit
            case .addOn:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.addOnDescriptionCharacterLimit
            case .addOnHeader:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.addOnHeaderDescriptionCharacterLimit
            case .singleTopicAddOn:
                return textView.text.count + (text.count - range.length) <= Constants.characterLimits.addOnDescriptionCharacterLimit
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
                let characterLeft = Constants.characterLimits.factTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .addOn:
                let characterLeft = Constants.characterLimits.addOnTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .addOnHeader:
                let characterLeft = Constants.characterLimits.addOnHeaderTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .argument:
                let characterLeft = Constants.characterLimits.argumentTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .deepArgument:
                let characterLeft = Constants.characterLimits.argumentTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .source:
                let characterLeft = Constants.characterLimits.sourceTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            case .singleTopicAddOn:
                let characterLeft = Constants.characterLimits.addOnTitleCharacterLimit-textView.text.count
                self.titleCharacterCountLabel.text = String(characterLeft)
            }
        } else {    // DescriptionTextView
            switch new { // Title no longer than x characters
            case .fact:
                let characterLeft = Constants.characterLimits.factDescriptionCharacterLimit-textView.text.count
                self.descriptionCharacterCountLabel.text = String(characterLeft)
            case .addOn:
                let characterLeft = Constants.characterLimits.addOnDescriptionCharacterLimit-textView.text.count
                self.descriptionCharacterCountLabel.text = String(characterLeft)
            case .addOnHeader:
                let characterLeft = Constants.characterLimits.addOnHeaderDescriptionCharacterLimit-textView.text.count
                self.descriptionCharacterCountLabel.text = String(characterLeft)
            case .singleTopicAddOn:
                let characterLeft = Constants.characterLimits.addOnDescriptionCharacterLimit-textView.text.count
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

extension NewFactViewController: LinkFactWithPostDelegate {
    func selectedFact(fact: Fact, isViewAlreadyLoaded: Bool) {
        self.selectedTopicIDForSingleTopicAddOn = fact.documentID
        self.topicPreviewLabel.text = fact.title.quoted
        if let url = URL(string: fact.imageURL) {
            topicPicturePreviewImageView.sd_setImage(with: url, completed: nil)
        } else {
            topicPicturePreviewImageView.image = UIImage(named: "FactStamp")
        }
    }
}

extension NewFactViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let image = selectedImageFromPicker {
            setImage(image: image)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    
    func setImage(image: UIImage) {
        topicPicturePreviewImageView.image = image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    func savePicture(userID: String, topicRef: DocumentReference) {
        
        if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 1) {
            let data = NSData(data: image)
            
            let imageSize = data.count/1000
            
            
            if imageSize <= 500 {   // When the imageSize is under 500kB it wont be compressed, because you can see the difference
                // No compression
                print("No compression")
                self.storeImage(data: image, topicRef: topicRef, userID: userID)
            } else if imageSize <= 1000 {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.4) {
                    
                    self.storeImage(data: image, topicRef: topicRef, userID: userID)
                }
            } else if imageSize <= 2000 {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.25) {
                    
                    self.storeImage(data: image, topicRef: topicRef, userID: userID)
                }
            } else {
                if let image = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.1) {
                    
                    self.storeImage(data: image, topicRef: topicRef, userID: userID)
                }
            }
            
        }
    }
    
    func storeImage(data: Data, topicRef: DocumentReference, userID: String) {
        
        let storageRef = Storage.storage().reference().child("factPictures").child("\(topicRef.documentID).png")
        
        storageRef.putData(data, metadata: nil, completion: { (metadata, error) in    //Bild speichern
            if let error = error {
                print(error)
                return
            }
            storageRef.downloadURL(completion: { (url, err) in  // Hier wird die URL runtergezogen
                if let err = err {
                    print(err)
                    return
                }
                if let url = url {
                    self.createNewFact(ref: topicRef, imageURL: url.absoluteString)
                }
            })
        })
    }
    
}
