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
    
    var imagePicker = UIImagePickerController()
    var imageURL = ""
    var selectedImageFromPicker = UIImage(named: "default-user")
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUserDetails()

        imagePicker.delegate = self
        cameraButton.alpha = 0
        cameraButton.isEnabled = false
        pictureFolderButton.alpha = 0
        pictureFolderButton.isEnabled = false
    }
    
    
    func getUserDetails() {
        
        let layer = profilePictureImageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = profilePictureImageView.frame.width/2
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        
        let user = Auth.auth().currentUser
        if let user = user {
            if let displayName = user.displayName {
                nameLabel.text = displayName
            }
            if let url = user.photoURL {
                profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
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
