//
//  ImagineFundViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.10.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class ImagineFundViewController: UIViewController {

    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width: CGFloat = 850
        let height:CGFloat = 3836
        
        let ratio = width / height
        let newWidth = self.view.frame.width
        let newHeight = newWidth / ratio

        imageViewHeight.constant = newHeight
        self.view.layoutIfNeeded()
    }
    

    

}
