//
//  NewBlogPostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class NewBlogPostViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var shortDescriptionTextfield: UITextView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var headerLabel: UILabel!
    
    var user:User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUser()
        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        shortDescriptionTextfield.resignFirstResponder()
        titleTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
        categoryTextField.resignFirstResponder()
    }
    
    func getUser() {
        if let user = Auth.auth().currentUser {
            self.user = HandyHelper().getUser(userUID: user.uid)
        }
    }
    
    @IBAction func selectImageButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        if user == nil {
            headerLabel.text = "Kein User da!"
        } else {
            
            if let user = user {
                
                let blogRef = Firestore.firestore().collection("BlogPosts")
                
                var dataDictionary: [String: Any] = ["title": titleTextField.text, "subtitle": shortDescriptionTextfield.text, "category" : categoryTextField.text, "description": descriptionTextView.text, "createDate": Timestamp(date: Date()), "profileImageURL": user.imageURL, "poster": user.name]
                
                
                blogRef.addDocument(data: dataDictionary)
                
                
                
                let alert = UIAlertController(title: "Fertig!", message: "Danke, dass du postest Malte!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                present(alert, animated: true) {        }
            }
        }
    }
    
}
