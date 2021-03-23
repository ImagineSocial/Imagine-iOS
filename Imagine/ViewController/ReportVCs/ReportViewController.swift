//
//  MeldenViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// Worked on this at the beginning of the idea, a lot of code needs to be refusrbished

enum reportCategory {
    case markVisually
    case violationOfRules
    case content
}

class ReportViewController: UIViewController {
    
    @IBOutlet weak var savePostButtonIcon: UIImageView!
    @IBOutlet weak var lowerStackView: UIStackView!
    @IBOutlet weak var savePostView: UIView!
    @IBOutlet weak var repostPostView: UIView!
    @IBOutlet weak var translatePostView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    
    var post: Post?
    var comment: Comment?
    var reportCategory: reportCategory?
    var repost : RepostType = .repost
    var reportComment = false
    
    let db = Firestore.firestore()
    
    let handyHelper = HandyHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if reportComment {
            savePostView.isHidden = true
            repostPostView.isHidden = true
            translatePostView.isHidden = true
        }
        
        checkIfItsYourPost()
        
        if let post = post {
            handyHelper.checkIfAlreadySaved(post: post) { (alreadySaved) in
                if alreadySaved {
                    self.savePostButtonIcon.tintColor = Constants.green
                } else {
                    if #available(iOS 13.0, *) {
                        self.savePostButtonIcon.tintColor = .label
                    } else {
                        self.savePostButtonIcon.tintColor = .black
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.alpha = 0.55
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = 0
        }
    }
    
    let deleteView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let trashImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "trash"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .label
        } else {
            imageView.tintColor = .black
        }
        
        return imageView
    }()
    
    let trashButton:DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showAlertForDeleteOption), for: .touchUpInside)
        button.setTitle(NSLocalizedString("delete_post_label", comment: "delete post"), for: .normal)
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
            button.backgroundColor = .systemBackground
        } else {
            button.setTitleColor(.black, for: .normal)
            button.backgroundColor = .white
        }
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 15)
        button.contentHorizontalAlignment = .left
        
        return button
    }()
    
    func insertDeleteView() {
        
        deleteView.addSubview(trashImage)
        trashImage.widthAnchor.constraint(equalToConstant: 20).isActive = true
        trashImage.leadingAnchor.constraint(equalTo: deleteView.leadingAnchor, constant: 8).isActive = true
        trashImage.centerYAnchor.constraint(equalTo: deleteView.centerYAnchor).isActive = true
        
        deleteView.addSubview(trashButton)
        trashButton.topAnchor.constraint(equalTo: deleteView.topAnchor).isActive = true
        trashButton.bottomAnchor.constraint(equalTo: deleteView.bottomAnchor).isActive = true
        trashButton.leadingAnchor.constraint(equalTo: trashImage.trailingAnchor, constant: 15).isActive = true
        trashButton.trailingAnchor.constraint(equalTo: deleteView.trailingAnchor).isActive = true
        trashButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        
        self.lowerStackView.insertArrangedSubview(deleteView, at: 0)
        self.lowerStackView.layoutIfNeeded()
    }
    
    func checkIfItsYourPost() {
        if let user = Auth.auth().currentUser {
            if let post = post {
                if user.uid == Constants.userIDs.uidMalte || user.uid == Constants.userIDs.uidSophie || user.uid == Constants.userIDs.uidYvonne {
                    if post.originalPosterUID == Constants.userIDs.FrankMeindlID || post.originalPosterUID == Constants.userIDs.MarkusRiesID || post.originalPosterUID == Constants.userIDs.AnnaNeuhausID || post.originalPosterUID == Constants.userIDs.LaraVoglerID || post.originalPosterUID == Constants.userIDs.LenaMasgarID  {
                        insertDeleteView()
                    }
                }
                if post.originalPosterUID == user.uid {
                    insertDeleteView()
                }
            }
        }
    }
    
    func deleteTopicPost(fact: Community) {
        guard let post = post else { return }
        
        var collectionRef: CollectionReference!
        if fact.language == .english {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(fact.documentID).collection("posts").document(post.documentID)
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("Error: \(error.localizedDescription)")
            } else {
                if let snap = snap {
                    ref.delete()
                    if let data = snap.data() {
                        if let addOnIDs = data["addOnDocumentIDs"] as? [String] {
                            for id in addOnIDs {
                                self.deletePostInAddOn(addOnID: id)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deletePostInAddOn(addOnID: String) {
        guard let post = post else { return }
        
        if let fact = post.fact {
            var collectionRef: CollectionReference!
            if fact.language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(fact.documentID).collection("addOns").document(addOnID).collection("items").document(post.documentID)
            
            ref.delete { (err) in
                if let error = err {
                    print("Error when deleting post in AddOn: \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    func deletePost() {
        guard let post = post else { return }
        
        let postRef: DocumentReference?
        var collectionRef: CollectionReference!
        if post.isTopicPost {
            if post.language == .english {
                collectionRef = db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = db.collection("TopicPosts")
            }
            postRef = collectionRef.document(post.documentID)
        } else {
            if post.language == .english {
                collectionRef = db.collection("Data").document("en").collection("posts")
            } else {
                collectionRef = db.collection("Posts")
            }
            postRef = collectionRef.document(post.documentID)
        }
        
        if let _ = post.thumbnailImageURL {
            deleteThumbnail(documentID: post.documentID)
        }
        
        if let fact = post.fact {
            self.deleteTopicPost(fact: fact)
        }
        if let postRef = postRef {
            postRef.delete { (err) in
                if let error = err {
                    print("We have an error deleting the post: \(error.localizedDescription)")
                } else {
                    print("Successfully deleted the post")
                }
            }
        }
        
        switch post.type {
        case .multiPicture:
            let id = post.documentID
            var index = 0
            if let imageURLs = post.imageURLs {
                for _ in imageURLs {
                    let storageRef = Storage.storage().reference().child("postPictures").child("\(id)-\(index).png")
                    
                    index+=1
                    storageRef.delete { (err) in
                        if let err = err {
                            print("We have an error deleting the old picture in storage: \(err.localizedDescription)")
                        } else {
                            print("Picture Deleted")
                            
                            let userPostRef = self.db.collection("Users").document(post.originalPosterUID).collection("posts").document(post.documentID)
                            
                            userPostRef.delete { (err) in
                                if let error = err {
                                    print("We have an error: \(error.localizedDescription)")
                                } else {
                                    if index == imageURLs.count {
                                        self.dismiss(animated: true, completion: nil)
                                        self.alert(message: "Fertig", title: "Das Bild wurde erfolgreich gelöscht. Aktualisiere den Feed und es ist weg")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        case .picture:
            let imageName = post.documentID
            let storageRef = Storage.storage().reference().child("postPictures").child("\(imageName).png")
            
            storageRef.delete { (err) in
                if let err = err {
                    print("We have an error deleting the old profile Picture: \(err.localizedDescription)")
                } else {
                    print("Picture Deleted")
                    
                    let userPostRef = self.db.collection("Users").document(post.originalPosterUID).collection("posts").document(post.documentID)
                    
                    userPostRef.delete { (err) in
                        if let error = err {
                            print("We have an error: \(error.localizedDescription)")
                        } else {
                            self.dismiss(animated: true, completion: nil)
                            self.alert(message: "Fertig", title: "Das Bild wurde erfolgreich gelöscht. Aktualisiere den Feed und es ist weg")
                        }
                    }
                }
            }
        default:
            let userPostRef = db.collection("Users").document(post.originalPosterUID).collection("posts").document(post.documentID)
            
            userPostRef.delete { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    self.dismiss(animated: true, completion: nil)
                    self.alert(message: "Fertig", title: "Der Post wurde erfolgreich gelöscht. Aktualisiere den Feed und er ist weg")
                }
            }
            print("No picture to delete")
        }
    }
    
    private func deleteThumbnail(documentID: String) {

        let storageRef = Storage.storage().reference().child("postPictures").child("\(documentID)-thumbnail.png")
        
        storageRef.delete { (err) in
            if let err = err {
                print("We have an error deleting the old thumbnail Picture: \(err.localizedDescription)")
            } else {
                print("Thumbnail Deleted")
            }
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
        case 0: reportCategory = .markVisually
            break
        case 1: reportCategory = .violationOfRules
            break
        case 3: reportCategory = .content
            break
        default:
            reportCategory = .content
        }
        if let _ = Auth.auth().currentUser {
            if let post = post {
                performSegue(withIdentifier: "reportOptionSegue", sender: post)
            } else if let comment = comment {
                performSegue(withIdentifier: "reportOptionSegue", sender: comment)
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func repostPressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            if let post = post {
                if post.type == .picture {
                    performSegue(withIdentifier: "toRepostSegue", sender: post)
                } else {
                    self.alert(message: "Im Moment kann man leider nur Bild-Beiträge reposten. Reiche gerne einen Vorschlag für dieses Feature ein, damit wir wissen, dass die Nachfrage da ist. Vielen Dank für dein Verständnis!")
                }
            }
        } else {
            self.notLoggedInAlert()
        }
    }
    
    @IBAction func translatePressed(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            self.repost = .translation
            if let post = post {
                if post.type == .picture {
                    performSegue(withIdentifier: "toRepostSegue", sender: post)
                } else {
                    self.alert(message: "Im Moment kann man leider nur Bild-Beiträge übersetzen. Reiche gerne einen Vorschlag für dieses Feature ein, damit wir wissen, dass die Nachfrage da ist. Vielen Dank für dein Verständnis!")
                }
            }
        } else {
            notLoggedInAlert()
        }
    }
    
    @IBAction func savePostTapped(_ sender: Any) {
        if let user = Auth.auth().currentUser {
            
            guard let post = post else { return }
            
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
        if let link = NSURL(string: "https://imagine.social")
        {
            let objectsToShare = [message, link] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let nextVC = segue.destination as? ReportOptionViewController {
            guard let category = self.reportCategory else {
                dismiss(animated: true, completion: nil)
                return
            }
            nextVC.reportCategory = category
            
            if let chosenPost = sender as? Post {
                nextVC.post = chosenPost
            } else if let chosenComment = sender as? Comment {
                nextVC.comment = chosenComment
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
