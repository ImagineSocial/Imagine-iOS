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

extension UITabBar {
    static let height: CGFloat = 48
    
//    override open func sizeThatFits(_ size: CGSize) -> CGSize {
//        guard let window = UIApplication.shared.keyWindow else {
//            return super.sizeThatFits(size)
//        }
//        var sizeThatFits = super.sizeThatFits(size)
//        if #available(iOS 13.0, *) {
//            print("Hasnt worked in Ios13")
//        } else if #available(iOS 11.0, *){
//            sizeThatFits.height = UITabBar.height + window.safeAreaInsets.bottom
//        } else {
//            sizeThatFits.height = UITabBar.height
//        }
//        return sizeThatFits
//    }
}

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBar.isTranslucent = false   //Prevents a bug/glitch where the items jump when going back from antother ViewController
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: Constants.imagineColor], for: .selected)
        
        }

    override func viewWillAppear(_ animated: Bool) {

    }
    
}
