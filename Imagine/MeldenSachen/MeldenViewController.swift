//
//  MeldenViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase


class MeldenViewController: UIViewController {

    @IBOutlet weak var savePostButtonIcon: UIImageView!
    
    var post = Post()
    var reportCategory = ""
    var repost = "repost"
    
    let db = Firestore.firestore()
    
    let handyHelper = HandyHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButtonIcon.tintColor = .green
            } else {
                self.savePostButtonIcon.tintColor = .black
            }
        }
    }
    

    @IBAction func dismissPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func reportOptionsScreenTapped(_ sender: DesignableButton) {
        switch sender.tag {
        case 0: reportCategory = "Optisch markieren"
            break
        case 1: reportCategory = "Schlechte Absicht"
            break
        case 2: reportCategory = "Lüge/Täuschung"
            break
        case 3: reportCategory = "Inhalt"
            break
        default:
            reportCategory = ""
        }
        
        performSegue(withIdentifier: "reportOptionSegue", sender: post)
    }
    
    @IBAction func repostPressed(_ sender: Any) {
        performSegue(withIdentifier: "toRepostSegue", sender: post)
    }
    
    @IBAction func translatePressed(_ sender: Any) {
        repost = "translation"
        performSegue(withIdentifier: "toRepostSegue", sender: post)
    }
    
    @IBAction func savePostTapped(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            let ref = db.collection("Users").document(user.uid).collection("saved").document()
            
            let data: [String:Any] = ["createTime": Timestamp(date: Date()), "documentID": post.documentID]
            
            ref.setData(data) { (err) in
                if let error = err {
                    print("We have an error saving this post: \(error.localizedDescription)")
                } else {
                    print("Successfully saved")
                    self.savePostButtonIcon.tintColor = .green
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let nextVC = segue.destination as? MeldeOptionViewController {
            nextVC.reportCategory = self.reportCategory
            
            if let chosenPost = sender as? Post {
                    nextVC.post = chosenPost
            }
        }
        if let repostVC = segue.destination as? RepostViewController {
            if let chosenPost = sender as? Post {
                repostVC.post = chosenPost
                repostVC.repost = self.repost
            }
        }
    }
}
