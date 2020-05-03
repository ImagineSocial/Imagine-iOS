//
//  EditProfileViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.04.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet weak var ageTextField: UITextField!
    
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        profilePictureImageView.layer.cornerRadius = 8
        let layer = statusTextView.layer
        layer.cornerRadius = 4
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.label.cgColor
        } else {
            layer.borderColor = UIColor.black.cgColor
        }
        layer.borderWidth = 0.5
        
        setUpUser()
    }
    
    func setUpUser() {
        guard let user = user else { return }
        
        if let url = URL(string: user.imageURL) {
            profilePictureImageView.sd_setImage(with: url, completed: nil)
        }
        
        nameTextField.text = user.displayName
    }
    
    
    @IBAction func changeProfilePictureTapped(_ sender: Any) {
    }
    
}
