//
//  RepostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseFirestore

class RepostViewController: UIViewController {
    
    @IBOutlet weak var originalTitelLabel: UILabel!
    @IBOutlet weak var titleTranslationTextView: UITextView!
    @IBOutlet weak var originalDescriptionLabel: UILabel!
    @IBOutlet weak var descriptionTranslationTextView: UITextView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var smallTitleTranslateLabel: UILabel!
    @IBOutlet weak var smallDescriptionTranslateLabel: UILabel!
    @IBOutlet weak var useOriginalTextButton: DesignableButton!
    
    var post = Post()
    var repost = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Das ist Repost: \(repost)")
        setPost()
        titleTranslationTextView.layer.cornerRadius = 5
        descriptionTranslationTextView.layer.cornerRadius = 5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTranslationTextView.resignFirstResponder()
        descriptionTranslationTextView.resignFirstResponder()
    }
    
    func setPost() {
        
        if repost == "translation" {
            
            useOriginalTextButton.isHidden = true
            
            originalTitelLabel.text = post.title
            originalTitelLabel.adjustsFontSizeToFitWidth = true
            originalTitelLabel.lineBreakMode = .byClipping
            originalTitelLabel.sizeToFit()
            
            
            
            if post.description == "" {
                originalDescriptionLabel.text = "Es wurde keine Beschreibung hinzugefügt"
                smallDescriptionTranslateLabel.text = "Schreib trotzdem eine Beschreibung wenn du möchtest!"
            } else {
                originalDescriptionLabel.text = post.description
            }
            
            if post.type == "picture" {
                postImageView.isHidden = false
                
                if let url = URL(string: post.imageURL) {
                    postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            } else {
                postImageView.isHidden = true
            }
        } else {    // Also Repost
            
            useOriginalTextButton.isHidden = false
            
            originalTitelLabel.text = post.title
            originalTitelLabel.adjustsFontSizeToFitWidth = true
            originalTitelLabel.lineBreakMode = .byClipping
            originalTitelLabel.sizeToFit()
            
            if post.description == "" {
                originalDescriptionLabel.text = "Es wurde keine Beschreibung hinzugefügt"
                smallDescriptionTranslateLabel.text = "Schreib trotzdem eine Beschreibung wenn du möchtest!"
            } else {
                originalDescriptionLabel.text = post.description
            }
            
            if post.type == "picture" {
                postImageView.isHidden = false
                
                if let url = URL(string: post.imageURL) {
                    postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            } else {
                postImageView.isHidden = true
            }
        }
    }
    
    @IBAction func useOriginalTextPressed(_ sender: Any) {
        titleTranslationTextView.text = post.title
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
        let postRef = Firestore.firestore().collection("Posts")
        
        let postRefDocumentID = postRef.document().documentID
        let dataDictionary: [String: Any] = ["title": titleTranslationTextView.text, "description": descriptionTranslationTextView.text, "documentID": postRefDocumentID, "createTime": getDate(), "type": repost, "OGpostDocumentID" : post.documentID, "report": "normal"]
        
        postRef.document(postRefDocumentID).setData(dataDictionary) // Glaube macht keinen Unterschied
        
        let alert = UIAlertController(title: "Done!", message: "Danke, dass du Wissen teilst!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true) {
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
