//
//  RepostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 30.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage
import FirebaseFirestore
import EasyTipView

enum RepostType {
    case repost
    case translation
}

class RepostViewController: UIViewController {
    
    @IBOutlet weak var originalTitelLabel: UILabel!
    @IBOutlet weak var titleTranslationTextView: UITextView!
    @IBOutlet weak var originalDescriptionLabel: UILabel!
    @IBOutlet weak var descriptionTranslationTextView: UITextView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var smallTitleTranslateLabel: UILabel!
    @IBOutlet weak var smallDescriptionTranslateLabel: UILabel!
    @IBOutlet weak var useOriginalTextButton: DesignableButton!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    var post: Post?
    var repost: RepostType = .repost
    
    var tipView: EasyTipView?
    let db = FirestoreRequest.shared.db
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        print("Das ist Repost: \(repost)")
        setPost()
        titleTranslationTextView.layer.cornerRadius = 5
        descriptionTranslationTextView.layer.cornerRadius = 5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        titleTranslationTextView.resignFirstResponder()
        descriptionTranslationTextView.resignFirstResponder()
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    func setPost() {
        
        guard let post = post else {
            return
        }

        
        switch repost {
        case .repost:
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
            
            
            switch post.type {
            case .picture:
                postImageView.isHidden = false
                
                if let link = post.image?.url, let url = URL(string: link) {
                    postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            case .multiPicture:
                postImageView.isHidden = false
                
                if let imageURL = post.images?.first?.url, let url = URL(string: imageURL) {
                    postImageView.sd_setImage(with: url, completed: nil)
                }
            default:
                postImageView.isHidden = true
            }
        case .translation:
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
            
            switch post.type {
            case .picture:
                postImageView.isHidden = false
                
                if let link = post.image?.url, let url = URL(string: link) {
                    postImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            default:
                postImageView.isHidden = true
            }
        }
    }
    
    @IBAction func useOriginalTextPressed(_ sender: Any) {
        titleTranslationTextView.text = post?.title
    }
    

    func getRepostTypeString() -> String {
        switch repost {
        case .translation:
            return "translation"
        case .repost:
            return "repost"
        }
    }
    
    @IBAction func sharePressed(_ sender: Any) {
        if titleTranslationTextView.text != nil {
            uploadRepost()
        } else {
            self.alert(message: "Füge bitte einen Titel hinzu")
        }
    }
    
    func uploadRepost() {
        
        guard let post = post, let documentID = post.documentID, let user = AuthenticationManager.shared.user else {
            notLoggedInAlert()
            return
        }
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection.language
        
        if language == .en {
            collectionRef = db.collection("Data").document("en").collection("posts")
        } else {
            collectionRef = db.collection("Posts")
        }
        let postRef = collectionRef.document()
        
        
        var dataDictionary: [String: Any] = ["title": titleTranslationTextView.text, "description": descriptionTranslationTextView.text, "createTime": Timestamp(date: Date()), "type": getRepostTypeString(), "OGpostDocumentID" : documentID, "report": "normal", "thanksCount":0, "wowCount":0, "haCount":0, "niceCount":0, "originalPoster": user.uid]
        
        if post.isTopicPost {
            dataDictionary["repostIsTopicPost"] = true
        }
        
        if post.language == .en {
            dataDictionary["repostLanguage"] = "en"
        } else {
            dataDictionary["repostLanguage"] = "de"
        }
        
        postRef.setData(dataDictionary, completion: { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                print("Successfully created repost")
            }
        })
        
        let alert = UIAlertController(title: NSLocalizedString("done", comment: "done"), message: NSLocalizedString("message_after_done_posting", comment: "thanks for sharing"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true) {
        }
    }
    
    @IBAction func backTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.createRepostText)
            tipView!.show(forItem: shareButton)
        }
    }
}
