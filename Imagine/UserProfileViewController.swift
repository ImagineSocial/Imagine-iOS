//
//  UserProfileViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 31.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseStorage
import FirebaseAuth
import SDWebImage

class UserProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var pictureFolderButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var profilePictureButton: DesignableButton!
    
    var imagePicker = UIImagePickerController()
    var posts = [Post]()
    var imageURL = ""
    var selectedImageFromPicker = UIImage(named: "default-user")
    var userUID = ""
    var yourOwnProfile = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        if userUID == "" {
            yourOwnProfile = true
            profilePictureButton.isEnabled = true
            if let user = Auth.auth().currentUser {
                sendData(UserUID: user.uid)
            }
        } else {
            logOutButton.isHidden = true
            profilePictureButton.isEnabled = false
            
            sendData(UserUID: userUID)
        }
        getUserDetails()
        
        
        imagePicker.delegate = self
        cameraButton.alpha = 0
        cameraButton.isEnabled = false
        pictureFolderButton.alpha = 0
        pictureFolderButton.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        yourOwnProfile = false
    }
    
    func sendData(UserUID : String) {
        if let CVC = children.last as? UserFeedTableViewController {
            CVC.setUID(UID: UserUID)
        }
    }
    
    func getUserDetails() {
        
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = profilePictureImageView.frame.width/2
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        
        if yourOwnProfile { // Wenn du es bist
            let user = Auth.auth().currentUser
            if let user = user {
                if let displayName = user.displayName {
                    nameLabel.text = displayName
                }
                if let url = user.photoURL {
                    profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                }
            }
        } else {    // Wenn du dir das Profil von jemand anderem ansiehst
            let userRef = Firestore.firestore().collection("Users").document(userUID)
            userRef.getDocument(completion: { (document, err) in
                if let document = document {
                    if let docData = document.data() {
                        
                        let name = docData["name"] as? String ?? ""
                        let surname = docData["surname"] as? String ?? ""
                        let profilePictureURL = docData["profilePictureURL"] as? String ?? ""
                        
                        self.nameLabel.text = "\(name) \(surname)"
                        
                        if profilePictureURL != "" {
                            if let url = URL(string: profilePictureURL) {
                                self.profilePictureImageView.sd_setImage(with: url, completed: nil)
                            }
                        }
                    }
                }
                
                if err != nil {
                    print("Wir haben einen Error beim User: \(err?.localizedDescription)")
                }
            })
            
        }
    }
    
    func savePicture() {
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("profilePictures").child("\(imageName).png")
        
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
                    }
                    
                    self.savePictureInUserDatabase()
                    
                    
                })
            })
        }
        
        
    }
    
    func savePictureInUserDatabase() {
        let user = Auth.auth().currentUser
        if let user = user {
            let changeRequest = user.createProfileChangeRequest()
            
            if let url = URL(string: imageURL) {
                changeRequest.photoURL = url
            }
            changeRequest.commitChanges { error in
                if error != nil {
                    // An error happened.
                    print("Wir haben einen error beim changeRequest: \(String(describing: error?.localizedDescription))")
                } else {
                    // Profile updated.
                    print("changeRequest hat geklappt")
                }
            }
            let userRef = Firestore.firestore().collection("Users").document(user.uid)
            //userRef.setData(["profilePictureURL": imageURL], merge: true)
            userRef.setData(["profilePictureURL": imageURL], mergeFields:["profilePictureURL"]) // MergeFields damit die anderen nicht überschrieben werden
        }
        
    }
    
    //Image Picker stuff
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let originalImage = info[.originalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        profilePictureImageView.image = selectedImageFromPicker
        
        savePicture()
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cameraButtonPressed(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        imagePicker.cameraDevice = .rear
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pictureFolderButtonPressed(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func profilePicturePressed(_ sender: Any) {
        
        if pictureFolderButton.isEnabled {
            pictureFolderButton.isEnabled = false
            cameraButton.isEnabled = false
            
            UIView.animate(withDuration: 2, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveLinear, animations: {
                self.cameraButton.alpha = 0
                self.pictureFolderButton.alpha = 0
            }, completion: nil)
        } else {
            pictureFolderButton.isEnabled = true
            cameraButton.isEnabled = true
            
            UIView.animate(withDuration: 2, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: .curveLinear, animations: {
                self.cameraButton.alpha = 1
                self.pictureFolderButton.alpha = 1
            }, completion: nil)
        }
    }
    
    @IBAction func dismissPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logOutPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Done!", message: "Danke für deine Weisheiten.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Abmelden", style: .destructive, handler: { (_) in
            // abmelden
            do {
                try Auth.auth().signOut()
                self.dismiss(animated: true, completion: nil)
            } catch {
                print("Ausloggen hat nicht funktioniert")
            }
        }))
        alert.addAction(UIAlertAction(title: "Doch nicht!", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true)
    }
    
}
