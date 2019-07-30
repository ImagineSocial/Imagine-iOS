//
//  NewPostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import SDWebImage

class NewPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var camButton: DesignableButton!
    @IBOutlet weak var camRollButton: DesignableButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var titleTextFieldLabel: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var linkTextFieldLabel: UILabel!
    
    @IBOutlet weak var shareButton: DesignableButton!
    @IBOutlet weak var markPostSwitch: UISwitch!
    @IBOutlet weak var markPostLabel: UILabel!
    @IBOutlet weak var markPostInfoButton: UIButton!
    @IBOutlet weak var markPostSegmentControl: UISegmentedControl!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var postOrEventSegmentControl: UISegmentedControl!
    @IBOutlet weak var pictureView: UIView!
    @IBOutlet weak var pictureViewLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeButton: DesignableButton!
    
    @IBOutlet weak var timeConstraint: NSLayoutConstraint!  // 60 when event
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerView: UIView!
    
    
    
    var imagePicker = UIImagePickerController()
    var selectedImageFromPicker = UIImage(named: "default")
    var selectedImageHeight: CGFloat = 0.0
    var selectedImageWidth: CGFloat = 0.0
    var imageURL = ""
    var reportType = ""
    var eventType = "activity"
    var camPic = false
    var postPost = true
    var selectDate = false
    var selectedDate: Date?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        datePicker.datePickerMode = .dateAndTime
        datePickerView.isHidden = true
        
        setPostUI()
        
        if Auth.auth().currentUser != nil { // Eingeloggt
            if let headerLabel = headerLabel {  // Wenn ich das nicht überprüfe crasht er
                headerLabel.text = "Teile deine Erfahrungen"
                shareButton.isHidden = false
            }
        } else {    // Nicht eingeloggt
            if let headerLabel = headerLabel {
                headerLabel.text = "Log dich ein um zu Posten! "
                shareButton.isHidden = true
            }
        }
        
        pictureView.layer.cornerRadius = 5
        pictureView.clipsToBounds = true
    }
    
    func setPostUI() {
        if let _ = Auth.auth().currentUser {
            headerLabel.text = "Teile deine Erfahrungen"
        } else {
            headerLabel.text = "Zum Posten bitte anmelden"
        }
        titleTextFieldLabel.text = "Titel:"
        titleTextField.placeholder = "Titel..."
        linkTextFieldLabel.text = "Link:"
        linkTextField.placeholder = "Link..."
        pictureViewLabel.text = "Füge ein Bild zu deinem Post hinzu:"
        
        
        self.timeLabel.isHidden = true
        self.timeButton.isHidden = true
        
        UIView.animate(withDuration: 1) {
            self.timeLabel.alpha = 0
            self.timeButton.alpha = 0
            self.timeConstraint.constant = 20
            self.markPostSegmentControl.alpha = 0
            self.markPostSegmentControl.isHidden = true
            self.view.layoutIfNeeded()
        }
        
        
        
        markPostSegmentControl.setTitle("Meinung", forSegmentAt: 0)
        markPostSegmentControl.setTitle("Sensation", forSegmentAt: 1)
        markPostSegmentControl.setTitle("Bearbeitet", forSegmentAt: 2)
        
        
        markPostLabel.isHidden = false
        markPostInfoButton.isHidden = false
        markPostSwitch.isHidden = false
        
        markPostSwitch.setOn(false, animated: true) // Auf aus stellen
    }
    
    func setEventUI() {
        if let _ = Auth.auth().currentUser {
            headerLabel.text = "Erstelle eine neue Veranstaltung"
        } else {
            headerLabel.text = "Zum Posten bitte anmelden"
        }
        
        titleTextFieldLabel.text = "Titel:"
        titleTextField.placeholder = "Titel..."
        linkTextFieldLabel.text = "Ort:"
        linkTextField.placeholder = "Ort..."
        pictureViewLabel.text = "Wähle ein Titelbild für die Veranstaltung:"
        
        
        
        markPostSegmentControl.setTitle("Veranstaltung", forSegmentAt: 0)
        markPostSegmentControl.setTitle("Projekt", forSegmentAt: 1)
        markPostSegmentControl.setTitle("Event", forSegmentAt: 2)
        markPostSegmentControl.alpha = 0
        markPostSegmentControl.isHidden = false
        
        markPostLabel.isHidden = true
        markPostInfoButton.isHidden = true
        markPostSwitch.isHidden = true
        
        self.timeLabel.isHidden = false
        self.timeButton.isHidden = false
        
        UIView.animate(withDuration: 1) {
            self.timeLabel.alpha = 1
            self.timeButton.alpha = 1
            self.timeConstraint.constant = 60
            self.markPostSegmentControl.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
        linkTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
        
        if let _ = Auth.auth().currentUser {
            
        } else {
            self.notLoggedInAlert()
        }
        
    }
    
    
    @IBAction func camPressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            imagePicker.sourceType = .camera
            imagePicker.cameraCaptureMode = .photo
            imagePicker.cameraDevice = .rear
            //imagePicker.allowsEditing = true
            
            present(imagePicker, animated: true, completion: nil)
        } else {
            self.notLoggedInAlert()
        }
    }
    @IBAction func CamRollPressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            imagePicker.sourceType = .photoLibrary
            //imagePicker.allowsEditing = true
        
            present(imagePicker, animated: true, completion: nil)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    
    
    
    //Image Picker stuff
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.shareButton.isEnabled = false      // Weil es erst hochgeladen werden muss
        
        /*if let editedImage = info[.editedImage] as? UIImage {
         selectedImageFromPicker = editedImage
         } else*/
        if picker.sourceType == .camera {
            self.camPic = true
        }
        if let originalImage = info[.originalImage] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImageSize = selectedImageFromPicker?.size {
            selectedImageHeight = selectedImageSize.height
            selectedImageWidth = selectedImageSize.width
        }
        
        previewImageView.isHidden = false
        previewImageView.image = selectedImageFromPicker
        
        // Noch keine Funktion für das abbrechen eines Posts, wird trotzdem in Firestore gespeichert
        savePicture()
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func savePicture() {
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("postPictures").child("\(imageName).png")
        
        if let uploadData = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.2) {   //Es war das Fragezeichen
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in    //Bild speichern
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
                        self.imageURL = url.absoluteString
                        self.shareButton.isEnabled = true
                    }
                })
            })
        }
    }
    
    // Geht einfacher
    func getDate() -> Timestamp {
        let date = Date()
        return Timestamp(date: date)
    }
    
    
    
    @IBAction func timeButtonTapped(_ sender: Any) {
        if selectDate {
            selectDate = false
            datePickerView.isHidden = true
            selectedDate = datePicker.date
            if let date = selectedDate {
                
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy, HH:mm"
                let stringDate = formatter.string(from: date)
                
                timeLabel.text = "Zeit:    \(stringDate) Uhr"
            }
            
            timeButton.setTitle("Zeit einstellen", for: .normal)
        } else {
            datePickerView.isHidden = false
            selectDate = true
            timeButton.setTitle("Zeit übernehmen", for: .normal)
        }
        
    }
    
    
    @IBAction func markPostSwitchPressed(_ sender: Any) {
        if markPostSwitch.isOn {
            markPostSegmentControl.isHidden = false
            UIView.animate(withDuration: 1) {
                self.markPostSegmentControl.alpha = 1
            }
            
            markPostLabel.isHidden = true
            reportType = "opinion"
        } else {
            UIView.animate(withDuration: 1) {
                self.markPostSegmentControl.alpha = 0
                self.markPostSegmentControl.isHidden = true
            }
            
            markPostLabel.isHidden = false
            reportType = ""
        }
    }
    
    @IBAction func markPostInfoButtonPressed(_ sender: Any) {
        // infoPopUp
    }
    
    
    @IBAction func postOrEventSegmentChanged(_ sender: Any) {
        if postOrEventSegmentControl.selectedSegmentIndex == 0 {
            // Noch löscht er alles vom alten Bildschirm
            setPostUI()
            postPost = true
        }
        if postOrEventSegmentControl.selectedSegmentIndex == 1 {
            // Noch löscht er alles vom alten Bildschirm
            setEventUI()
            postPost = false
        }
    }
    
    
    @IBAction func markPostSegmentChanged(_ sender: Any) {
        if postPost {   // If you want to post a post
            if markPostSegmentControl.selectedSegmentIndex == 0 {
                reportType = "opinion"
            }
            if markPostSegmentControl.selectedSegmentIndex == 1 {
                reportType = "sensationalism"
            }
            if markPostSegmentControl.selectedSegmentIndex == 2 {
                reportType = "edited"
            }
        } else {    // If you want to post an event
            if markPostSegmentControl.selectedSegmentIndex == 0 {
                reportType = "activity"
            }
            if markPostSegmentControl.selectedSegmentIndex == 1 {
                reportType = "project"
            }
            if markPostSegmentControl.selectedSegmentIndex == 2 {
                reportType = "event"
            }
        }
    }
    
    @IBAction func sharePressed(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            
            let ref = Firestore.firestore()
            let userID = user.uid
            
            if postPost {   // Means you post a post
                
                let postRef = ref.collection("Posts")
                
                let postRefDocumentID = postRef.document().documentID
                
                let userRef = Firestore.firestore().collection("Users").document(userID).collection("posts").document(postRefDocumentID)
                
                userRef.setData(["createTime": getDate()])      // Post zum User hinzufügen!
                
                var dataDictionary: [String: Any] = ["title": titleTextField.text, "description": textView.text, "createTime": getDate(), "originalPoster": userID, "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0,]
                // DocumentID gelöscht 13.06
                
                if let _ = linkTextField.text?.youtubeID {  // YouTubeVideo
                    dataDictionary["type"] = "youTubeVideo"
                    dataDictionary["link"] = linkTextField.text
                    
                    print("YouTubeVideo Postet")
                    
                } else if linkTextField.text != "" {    // Normal Link
                    dataDictionary["type"] = "link"
                    dataDictionary["link"] = linkTextField.text
                    
                    print("link posted")
                } else if selectedImageFromPicker != UIImage(named: "default") {
                    dataDictionary["type"] = "picture"
                    dataDictionary["imageURL"] = imageURL
                    dataDictionary["imageHeight"] = Double(selectedImageHeight)
                    dataDictionary["imageWidth"] = Double(selectedImageWidth)
                    
                    print("picture posted")
                    
                } else if selectedImageFromPicker == UIImage(named: "default") && linkTextField.text == "" {
                    dataDictionary["type"] = "thought"
                    
                    print("thought posted")
                }
                
                switch reportType {
                case "":
                    dataDictionary["report"] = "normal"
                case "opinion":
                    dataDictionary["report"] = "opinion"
                case "sensationalism":
                    dataDictionary["report"] = "sensationalism"
                case "edited":
                    dataDictionary["report"] = "edited"
                default:
                    dataDictionary["report"] = "normal"
                }
                
                postRef.document(postRefDocumentID).setData(dataDictionary)
                
                if camPic { // Um es auf in dem Handy-Photo Ordner zu speichern Geht besser :/
                    if let selectedImage = selectedImageFromPicker {
                        UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
                    }
                }
                
                
                
                let alert = UIAlertController(title: "Done!", message: "Danke für deine Weisheiten.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                present(alert, animated: true) {
                    self.textView.text.removeAll()
                    self.linkTextField.text?.removeAll()
                    self.titleTextField.text?.removeAll()
                    if let image = UIImage(named: "default") {
                        self.previewImageView.image = image
                    }
                }
            } else {    //  means it is an event
                let eventRef = ref.collection("Events")
                let eventRefDocumentID = eventRef.document().documentID
                let participants: [String] = [userID]
                
                // Type muss noch eingestellt werden
                
                let userRef = Firestore.firestore().collection("Users").document(userID).collection("events").document(eventRefDocumentID)
                
                userRef.setData(["createTime": getDate()])      // Event zum User hinzufügen!
                
                if let date = selectedDate {
                    
                    let timestamp = Timestamp(date: date)
                    
                    var dataDictionary: [String: Any] = ["title": titleTextField.text, "description": textView.text, "createDate": getDate(), "admin": userID, "location": linkTextField.text, "imageURL": imageURL, "imageHeight": Double(selectedImageHeight), "imageWidth": Double(selectedImageWidth), "type": eventType, "participants": participants, "time": timestamp]
                    
                    eventRef.document(eventRefDocumentID).setData(dataDictionary)
                    
                    if camPic { // Um es auf in dem Handy-Photo Ordner zu speichern Geht besser :/
                        if let selectedImage = selectedImageFromPicker {
                            UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
                        }
                    }
                    
                    
                    
                    let alert = UIAlertController(title: "Done!", message: "Danke, dass du die Menschen zusammenbringst", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        
                    }))
                    present(alert, animated: true) {
                        self.textView.text.removeAll()
                        self.linkTextField.text?.removeAll()
                        self.titleTextField.text?.removeAll()
                        if let image = UIImage(named: "default") {
                            self.previewImageView.image = image
                        }
                    }
                } else {    // Kein Datum angegeben
                    
                    
                }
            }
        }
    }
    
}
