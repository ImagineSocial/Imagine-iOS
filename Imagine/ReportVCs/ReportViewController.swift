//
//  MeldenViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
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
    
    let db = FirestoreRequest.shared.db
    
    let handyHelper = HandyHelper.shared
    
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
                    self.savePostButtonIcon.tintColor = .label
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
        view.backgroundColor = .systemBackground
        
        return view
    }()
    
    let trashImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "trash"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        
        return imageView
    }()
    
    let trashButton:DesignableButton = {
        let button = DesignableButton(title: NSLocalizedString("delete_post_label", comment: "delete post"), font: UIFont(name: "IBMPlexSans", size: 15))

        button.titleLabel?.textAlignment = .left
        button.addTarget(self, action: #selector(showAlertForDeleteOption), for: .touchUpInside)
        
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
        if let currentUser = AuthenticationManager.shared.user, let post = post, let user = post.user {
            if currentUser.uid == Constants.userIDs.uidMalte || user.uid == currentUser.uid {
                insertDeleteView()
            }
        }
    }
    
    func deleteTopicPost(community: Community) {
        guard let post = post, let documentID = post.documentID, let communityID = community.id else { return }
        
        var collectionRef: CollectionReference!
        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(communityID).collection("posts").document(documentID)
        
        ref.getDocument { (snap, err) in
            if let error = err {
                print("Error: \(error.localizedDescription)")
            } else {
                if let snap = snap, let data = snap.data(), let addOnIDs = data["addOnDocumentIDs"] as? [String] {
                    for id in addOnIDs {
                        self.deletePostInAddOn(addOnID: id)
                        ref.delete()
                    }
                }
            }
        }
    }
    
    func deletePostInAddOn(addOnID: String) {
        guard let post = post, let documentID = post.documentID, let community = post.community, let communityID = community.id else { return }
        
        var collectionRef: CollectionReference!
        if community.language == .en {
            collectionRef = db.collection("Data").document("en").collection("topics")
        } else {
            collectionRef = db.collection("Facts")
        }
        let ref = collectionRef.document(communityID).collection("addOns").document(addOnID).collection("items").document(documentID)
        
        ref.delete { (err) in
            if let error = err {
                print("Error when deleting post in AddOn: \(error.localizedDescription)")
            }
        }
    }
    
    func deletePost() {
        guard let post = post, let userID = post.user?.uid, let documentID = post.documentID else { return }
        
        let postRef: DocumentReference?
        var collectionRef: CollectionReference!
        if post.isTopicPost {
            if post.language == .en {
                collectionRef = db.collection("Data").document("en").collection("topicPosts")
            } else {
                collectionRef = db.collection("TopicPosts")
            }
            postRef = collectionRef.document(documentID)
        } else {
            if post.language == .en {
                collectionRef = db.collection("Data").document("en").collection("posts")
            } else {
                collectionRef = db.collection("Posts")
            }
            postRef = collectionRef.document(documentID)
        }
        
        if let _ = post.image?.thumbnailUrl {
            deleteThumbnail(documentID: documentID)
        }
        
        if let community = post.community {
            self.deleteTopicPost(community: community)
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
            var index = 0
            guard let images = post.images else {
                return
            }
            for _ in images {
                let storageRef = Storage.storage().reference().child("postPictures").child("\(documentID)-\(index).png")
                
                index+=1
                storageRef.delete { (err) in
                    if let err = err {
                        print("We have an error deleting the old picture in storage: \(err.localizedDescription)")
                    } else {
                        print("Picture Deleted")
                        
                        let userPostRef = self.db.collection("Users").document(userID).collection("posts").document(documentID)
                        
                        userPostRef.delete { (err) in
                            if let error = err {
                                print("We have an error: \(error.localizedDescription)")
                            } else {
                                if index == images.count {
                                    self.dismiss(animated: true, completion: nil)
                                    self.alert(message: "Fertig", title: "Das Bild wurde erfolgreich gelöscht. Aktualisiere den Feed und es ist weg")
                                }
                            }
                        }
                    }
                }
            }
        case .picture, .panorama:
            let storageRef = Storage.storage().reference().child("postPictures").child("\(documentID).png")
            
            storageRef.delete { (err) in
                if let err = err {
                    print("We have an error deleting the old profile Picture: \(err.localizedDescription)")
                } else {
                    print("Picture Deleted")
                    
                    let userPostRef = self.db.collection("Users").document(userID).collection("posts").document(documentID)
                    
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
            let userPostRef = db.collection("Users").document(userID).collection("posts").document(documentID)
            
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
        dismiss(animated: true)
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
        if AuthenticationManager.shared.isLoggedIn {
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
        if AuthenticationManager.shared.isLoggedIn {
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
        if AuthenticationManager.shared.isLoggedIn {
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
        guard AuthenticationManager.shared.user != nil, let post = post else {
            self.notLoggedInAlert()
            return
        }
        
        post.savePost { success in
            if success {
                self.savePostButtonIcon.tintColor = Constants.green
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
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
