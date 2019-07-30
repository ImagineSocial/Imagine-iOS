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

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.isTranslucent = true
//        self.navigationController?.view.backgroundColor = UIColor.clear
        
        setBarButton()
    }
    

    let barButtonForCommunityVC : DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 75).isActive = true
        button.heightAnchor.constraint(equalToConstant: 25).isActive = true
        button.layer.cornerRadius = 4
        button.setTitle("Vision >", for: .normal)
        button.backgroundColor = UIColor(red:0.00, green:0.60, blue:1.00, alpha:1.0)
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        
        return button
    }()
    
    @objc func goToVision() {
        performSegue(withIdentifier: "toVisionSegue", sender: nil)
    }
    
    func setBarButton() {
        
        barButtonForCommunityVC.addTarget(self, action: #selector(goToVision), for: .touchUpInside)
        let rightBarButton = UIBarButtonItem(customView: barButtonForCommunityVC)
        rightBarButton.tintColor = .black
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
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
    }
}
