//
//  TabBarViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 31.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import SDWebImage

class TabBarViewController: UITabBarController {

    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        //create a new button
        let button = DesignableButton(type: .custom)
        //set frame
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        //add function for button
        button.addTarget(self, action: #selector(BarButtonItemTapped), for: .touchUpInside)
        
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.layer.borderWidth =  0.1
        button.layer.borderColor = UIColor.black.cgColor
        
        // Wenn jemand eingeloggt ist:
        if let user = Auth.auth().currentUser {
            if let url = user.photoURL{
                do {
                    let data = try Data(contentsOf: url)
                    
                    if let image = UIImage(data: data) {
                        
                        //set image for button
                        button.setImage(image, for: .normal)
                        button.widthAnchor.constraint(equalToConstant: 35).isActive = true
                        button.heightAnchor.constraint(equalToConstant: 35).isActive = true
                        button.layer.cornerRadius = button.frame.width/2
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
            }
            
        } else {    // Wenn niemand eingeloggt
            
            button.widthAnchor.constraint(equalToConstant: 50).isActive = true
            button.heightAnchor.constraint(equalToConstant: 25).isActive = true
            button.layer.cornerRadius = 5
            
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            button.setTitle("Log-In", for: .normal)
            button.backgroundColor = UIColor(red:0.68, green:0.77, blue:0.90, alpha:1.0)
        }
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    
    @objc func BarButtonItemTapped() {
        // If not eingeloggt...
        if Auth.auth().currentUser == nil {
            performSegue(withIdentifier: "logInSegue", sender: nil)
        } else {
            performSegue(withIdentifier: "toProfileSegue", sender: nil)
        }
    }
    
    
}
