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
    @IBOutlet weak var lowerStackView: UIStackView!
    @IBOutlet weak var lowerStackViewHeightConstraint: NSLayoutConstraint!
    
    var post = Post()
    var reportCategory = ""
    var repost : RepostType = .repost
    
    let db = Firestore.firestore()
    
    let handyHelper = HandyHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
            if alreadySaved {
                self.savePostButtonIcon.tintColor = Constants.green
            } else {
                self.savePostButtonIcon.tintColor = .black
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkIfItsYourPost()
    }
    
    let deleteView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        
        return view
    }()
    
    let trashImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "trash"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        
        return imageView
    }()
    
    let trashButton:DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showAlertForDeleteOption), for: .touchUpInside)
        button.setTitle("Post löschen", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.tintColor = .black
        button.backgroundColor = .white
        button.titleLabel?.font = UIFont(name: "Symbol", size: 20)
        
        return button
    }()
    
    func insertDeleteView() {
        deleteView.addSubview(trashButton)
        trashButton.topAnchor.constraint(equalTo: deleteView.topAnchor).isActive = true
        trashButton.bottomAnchor.constraint(equalTo: deleteView.bottomAnchor).isActive = true
        trashButton.leadingAnchor.constraint(equalTo: deleteView.leadingAnchor).isActive = true
        trashButton.trailingAnchor.constraint(equalTo: deleteView.trailingAnchor).isActive = true
        
        deleteView.addSubview(trashImage)
        trashImage.widthAnchor.constraint(equalToConstant: 50).isActive = true
        trashImage.leadingAnchor.constraint(equalTo: deleteView.leadingAnchor, constant: 5).isActive = true
        trashImage.centerYAnchor.constraint(equalTo: deleteView.centerYAnchor).isActive = true
        
        self.lowerStackView.insertArrangedSubview(deleteView, at: 0)
        self.lowerStackViewHeightConstraint.constant = 230
        self.lowerStackView.layoutIfNeeded()
    }
    
    func checkIfItsYourPost() {
        if let user = Auth.auth().currentUser {
            if post.originalPosterUID == user.uid {
                insertDeleteView()
            }
        }
    }
    
    func deletePost() {
        let postRef = db.collection("Posts").document(post.documentID)
        postRef.delete()
        
        switch post.type {
        case .picture:
            let imageName = "\(post.documentID)"
            let storageRef = Storage.storage().reference().child("postPictures").child("\(imageName).png")
            
            storageRef.delete { (err) in
                if let err = err {
                    print("We have an error deleting the old profile Picture: \(err.localizedDescription)")
                } else {
                    print("Picture Deleted")
                    
                    let userPostRef = self.db.collection("Users").document(self.post.originalPosterUID).collection("posts").document(self.post.documentID)
                    userPostRef.delete()
                    userPostRef.delete { (err) in
                        if let error = err {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        default:
            let userPostRef = db.collection("Users").document(post.originalPosterUID).collection("posts").document(post.documentID)
            userPostRef.delete()
            userPostRef.delete { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            print("No picture to delete")
        }
    }
    
    @objc func showAlertForDeleteOption() {
        let alert = UIAlertController(title: "Post löschen", message: "Bist du dir sicher, dass du den Post vollständig löschen möchtest?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Löschen", style: .destructive , handler: { (_) in
            // delete
            self.deletePost()
        }))
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true)
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
            repost = .translation
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
                    self.savePostButtonIcon.tintColor = Constants.green
                    
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
        if let navVC = segue.destination as? UINavigationController {
            if let repostVC = navVC.topViewController as? RepostViewController {
                if let chosenPost = sender as? Post {
                    repostVC.post = chosenPost
                    repostVC.repost = self.repost
                }
            }
        }
    }
}
