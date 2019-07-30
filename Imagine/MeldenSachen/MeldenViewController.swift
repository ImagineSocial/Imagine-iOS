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

        
        self.savePostButtonIcon.tintColor = .black
        
        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButtonIcon.tintColor = .green
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
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "reportOptionSegue", sender: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func repostPressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toRepostSegue", sender: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func translatePressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            repost = "translation"
            performSegue(withIdentifier: "toRepostSegue", sender: post)
        } else {
            notLoggedInAlert()
        }
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
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func sharePostTapped(_ sender: Any) {
        //Set the default sharing message.
        let message = "Lade dir jetzt Imagine runter!"
        //Set the link to share.
        if let link = NSURL(string: "http://yoururl.com")
        {
            let objectsToShare = [message] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
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
