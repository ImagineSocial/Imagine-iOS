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
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var shareButton: DesignableButton!
    @IBOutlet weak var markPostSwitch: UISwitch!
    @IBOutlet weak var markPostLabel: UILabel!
    @IBOutlet weak var markPostInfoButton: UIButton!
    @IBOutlet weak var markPostSegmentControl: UISegmentedControl!
    @IBOutlet weak var headerLabel: UILabel!
    
    var imagePicker = UIImagePickerController()
    var selectedImageFromPicker = UIImage(named: "default")
    var selectedImageHeight: CGFloat = 0.0
    var selectedImageWidth: CGFloat = 0.0
    var imageURL = ""
    var reportType = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
        linkTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
    
    
    @IBAction func camPressed(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.cameraDevice = .rear
        //imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func CamRollPressed(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        //imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func savePicture() {
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("postPictures").child("\(imageName).png")
        
        if let uploadData = self.selectedImageFromPicker?.jpegData(compressionQuality: 0.1) {   //Es war das Fragezeichen
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
    
    
    //Image Picker stuff
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.shareButton.isEnabled = false      // Weil es erst hochgeladen werden muss
        
        /*if let editedImage = info[.editedImage] as? UIImage {
         selectedImageFromPicker = editedImage
         } else*/
        if let originalImage = info[.originalImage] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImageSize = selectedImageFromPicker?.size {
            selectedImageHeight = selectedImageSize.height
            selectedImageWidth = selectedImageSize.width
        }
        
        previewImageView.isHidden = false
        previewImageView.image = selectedImageFromPicker
        
        savePicture()
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
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
    
    
    @IBAction func sharePressed(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            
        let postRef = Firestore.firestore().collection("Posts")
        let userID = user.uid
        
            
            
        let postRefDocumentID = postRef.document().documentID
            
        let userRef = Firestore.firestore().collection("Users").document(userID).collection("posts").document(postRefDocumentID)
            
            userRef.setData(["createTime": getDate()])      // Post zum User hinzufügen!
            
            var dataDictionary: [String: Any] = ["title": titleTextField.text, "description": textView.text, "documentID": postRefDocumentID, "createTime": getDate(), "originalPoster": userID]
        
        
        if linkTextField.text != "" {
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
        
        postRef.document(postRefDocumentID).setData(dataDictionary) // Glaube macht keinen Unterschied
        
        if let selectedImage = selectedImageFromPicker {    // Um es auf in dem Handy-Photo Ordner zu speichern
            UIImageWriteToSavedPhotosAlbum(selectedImage, nil, nil, nil)
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
        }
    }
    
    
    @IBAction func markPostSwitchPressed(_ sender: Any) {
        if markPostSwitch.isOn {
            markPostSegmentControl.isHidden = false
            markPostLabel.isHidden = true
            reportType = "opinion"
        } else {
            markPostSegmentControl.isHidden = true
            markPostLabel.isHidden = false
            reportType = ""
        }
    }
    
    @IBAction func markPostInfoButtonPressed(_ sender: Any) {
        // infoPopUp
    }
    @IBAction func markPostSegmentChanged(_ sender: Any) {
        if markPostSegmentControl.selectedSegmentIndex == 0 {
            reportType = "opinion"
        }
        if markPostSegmentControl.selectedSegmentIndex == 1 {
            reportType = "sensationalism"
        }
        if markPostSegmentControl.selectedSegmentIndex == 2 {
            reportType = "edited"
        }
    }
    
}
