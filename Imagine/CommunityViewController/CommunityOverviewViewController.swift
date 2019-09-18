//
//  CommunityOverviewViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(showSecretButton))
        gesture.allowableMovement = 500
        gesture.minimumPressDuration = 3
        self.view.addGestureRecognizer(gesture)
        
        upperRightButton.backgroundColor = Constants.imagineColor
        howCanIHelpButton.backgroundColor = Constants.imagineColor
        imagineBlogButton.backgroundColor = Constants.imagineColor
        communityChatButton.backgroundColor = Constants.imagineColor
        voteButton.backgroundColor = Constants.imagineColor
        
        
        visionButton.imageView?.contentMode = .scaleAspectFit
        let vLayer = visionButton.layer
        vLayer.cornerRadius = 4
        vLayer.borderColor = Constants.imagineColor.cgColor
        vLayer.borderWidth = 2
        moreButtonTapped.imageView?.contentMode = .scaleAspectFit
        let mLayer = moreButtonTapped.layer
        mLayer.cornerRadius = 4
        mLayer.borderColor = Constants.imagineColor.cgColor
        mLayer.borderWidth = 2
        
        print( self.view.frame.height, "Height")
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
        }) { (_) in
            self.buttonStackView.isHidden = true
            self.secretButton.alpha = 0
            self.secretButton.isHidden = false
            
            UIView.animate(withDuration: 2, animations: {
                self.secretButton.alpha = 1
            }, completion: { (_) in
                
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
        let info = Info(title: "Imagine-Grundsatz", image: UIImage(named: "HippySign"), description: "Kommunikation, Transparenz und soziale Verantwortung sind für uns die wichtigsten Merkmale für ein faires Miteinander zwischen User/Kunde und Unternehmen.  Wir hoffen, dass in Zukunft Unternehmen eine offene Atmosphäre zu ihren Kunden aufbauen und pflegen. Ihr gegenseitliches Handeln sollte verständlich dargelegt und nicht in langen Datenschutz- und Nutzungsrichtlinien verschlüsselt werden.  Firmen suchen trotz hoher Einnahmen, Steuer- und Gesetzeslücken um ihren Profit zu maximieren, während die User und Allgemeinheit nicht berücksichtigt werden.   Das Umdenken der Unternehmen muss eingefordert werden. Im Informationszeitalter haben Konsumenten die Möglichkeit sich zu vernetzen, ihre Rechte einzufordern und die derzeitige Profitgier anzuprangern. ")
        
        performSegue(withIdentifier: "toPrincipleInfo", sender: info)
    }
    
    @IBAction func secretButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSecretSegue", sender: nil)
    }
}
