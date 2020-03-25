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
    let db = Firestore.firestore()
    
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
            self.user = HandyHelper().getUserForNewBlogpostOnly(userUID: user.uid)
        }
    }
    
    @IBAction func selectImageButtonTapped(_ sender: Any) {
    }
    
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        if user == nil {
            headerLabel.text = "Kein User da!"
        } else {
            
            if let user = user {
                
                let blogRef = db.collection("BlogPosts")
                
                let dataDictionary: [String: Any] = ["title": titleTextField.text, "subtitle": shortDescriptionTextfield.text, "category" : categoryTextField.text, "description": descriptionTextView.text, "createDate": Timestamp(date: Date()), "profileImageURL": user.imageURL, "poster": "Imagine"]
                
                
                blogRef.addDocument(data: dataDictionary)
                
                self.getEveryUserAndSetNotification()
                
                
                let alert = UIAlertController(title: "Fertig!", message: "Danke, dass du postest Malte!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                    
                }))
                present(alert, animated: true) {        }
            }
        }
    }
    
    func getEveryUserAndSetNotification() {
        db.collection("Users").getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                for doc in snap!.documents {
                    let documentID = doc.documentID
                    self.setNotification(documentID: documentID)
                }
            }
        }
    }
    
    func setNotification(documentID: String) {
        let ref = db.collection("Users").document(documentID).collection("notifications").document()

        let data:[String:Any] = ["type": "blogPost"]
        ref.setData(data) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("set Notification")
            }
        }
    }
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
