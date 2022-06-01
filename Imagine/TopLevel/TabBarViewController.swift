//
//  TabBarViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 31.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseAuth
import SDWebImage

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.imagineColor], for: .normal)
        //Doesnt work
        }

    override func viewWillAppear(_ animated: Bool) {

    }
    
}
