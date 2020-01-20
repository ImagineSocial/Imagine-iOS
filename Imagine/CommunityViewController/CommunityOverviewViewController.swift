//
//  CommunityOverviewViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

extension UIViewController {
    
    func alert(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func notLoggedInAlert() {
        let alertController = UIAlertController(title: "Nicht Angemeldet", message: "Melde dich an um alle Funktionen bei Imagine zu nutzen!", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

class CommunityOverviewViewController: UIViewController {
    
    @IBOutlet weak var visionButton: DesignableButton!
    @IBOutlet weak var moreButtonTapped: DesignableButton!
    @IBOutlet weak var howCanIHelpButton: DesignableButton!
    @IBOutlet weak var imagineBlogButton: DesignableButton!
    @IBOutlet weak var communityChatButton: DesignableButton!
    @IBOutlet weak var voteButton: DesignableButton!
    @IBOutlet weak var upperRightButton: DesignableButton!
    @IBOutlet weak var secretButton: DesignableButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var newCampaignButton: UIButton!
    
    
    let db = Firestore.firestore()
    private let cornerRadius:CGFloat = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(showSecretButton))
        gesture.allowableMovement = 500
        gesture.minimumPressDuration = 3
        self.view.addGestureRecognizer(gesture)
        
        
        let buttons : [UIButton] = [visionButton, moreButtonTapped, upperRightButton,imagineBlogButton,communityChatButton,voteButton]
        
        for button in buttons {
            let layer = button.layer
            layer.cornerRadius = cornerRadius
//            layer.borderColor = Constants.imagineColor.cgColor
//            layer.borderWidth = 2
        }
        
        voteButton.titleLabel?.numberOfLines = 0
        voteButton.titleLabel?.textAlignment = .center
        howCanIHelpButton.layer.cornerRadius = cornerRadius
        
        if self.view.frame.height >= 800 {
            howCanIHelpButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 22)
            imagineBlogButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 22)
            communityChatButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 22)
            voteButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 22)
            
        } else if self.view.frame.height <= 600 {
            howCanIHelpButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
            imagineBlogButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
            communityChatButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
            voteButton.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
        }
        
        if let user = Auth.auth().currentUser {
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                self.setNotifierForAdmin()
            }
        }
        
    }
    
    
    
    @IBAction func communityChatTapped(_ sender: Any) {
        let chat = Chat()
        chat.documentID = "CommunityChat"
        
        performSegue(withIdentifier: "toChatSegue", sender: chat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toChatSegue" {
            if let chosenChat = sender as? Chat {
                if let chatVC = segue.destination as? ChatViewController {
                    chatVC.chat = chosenChat
                    chatVC.chatSetting = .community
                }
            }
        }
        
        if segue.identifier == "toVisionSegue" {
            if let visionVC = segue.destination as? SwipeCollectionViewController {
                visionVC.diashow = .vision
            }
        }
        
        if segue.identifier == "toPrincipleInfo" {
            if let info = sender as? Info {
                if let vc = segue.destination as? BlogPostViewController {
                    vc.info = info
                }
            }
        }
    }
    
    @objc func showSecretButton() {
        UIView.animate(withDuration: 2, animations: {
            self.buttonStackView.alpha = 0
            self.visionButton.alpha = 0
            self.moreButtonTapped.alpha = 0
            self.howCanIHelpButton.alpha = 0
            self.imagineBlogButton.alpha = 0
            self.communityChatButton.alpha = 0
            self.voteButton.alpha = 0
        }) { (_) in
            self.buttonStackView.isHidden = true
            self.visionButton.isHidden = true
            self.moreButtonTapped.isHidden = true
            self.howCanIHelpButton.isHidden = true
            self.imagineBlogButton.isHidden = true
            self.communityChatButton.isHidden = true
            self.voteButton.isHidden = true
            self.secretButton.alpha = 0
            self.secretButton.isHidden = false
            
            UIView.animate(withDuration: 2, animations: {
                self.secretButton.alpha = 1
            }, completion: { (_) in
                
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.buttonStackView.isHidden = false
        self.buttonStackView.alpha = 1
        self.secretButton.isHidden = true
    }
    
    @IBAction func visionButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toVisionSegue", sender: nil)
    }
    @IBAction func manifestoButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toTopicsSegue", sender: nil)
    }
    
    @IBAction func principleButtonTapped(_ sender: Any) {
        let info = Info(title: "Imagine-Grundsatz", image: UIImage(named: "ImagineSign"), description: Constants.texts.principleText)
        
        if let user = Auth.auth().currentUser {
            if user.uid == "CZOcL3VIwMemWwEfutKXGAfdlLy1" {
                print("Nicht bei Malte loggen")
            } else {
                Analytics.logEvent("PrincipleOpened", parameters: [:])
            }
        } else {
            Analytics.logEvent("PrincipleOpened", parameters: [:])
        }
        
        performSegue(withIdentifier: "toPrincipleInfo", sender: info)
    }
    
    @IBAction func secretButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }
    
    @IBAction func newCampaignButtonTapped(_ sender: Any) {
        if let _ = Auth.auth().currentUser {
            performSegue(withIdentifier: "toNewCampaignSegue", sender: nil)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    
    func setNotifierForAdmin() {
        let ref = db.collection("Reports")
        ref.getDocuments { (snap, err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                let count = snap!.count
                
                if let tabItems = self.tabBarController?.tabBar.items {
                    let tabItem = tabItems[4] //Community
                    if count != 0 {
                        tabItem.badgeValue = String(count)
                    }
                }
                
            }
        }
    }
}
