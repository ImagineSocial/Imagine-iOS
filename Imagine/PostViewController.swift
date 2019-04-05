//
//  PostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Kingfisher


class PostViewController: UIViewController {
    
    @IBOutlet weak var aboveNavBarView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    var post = Post()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        showPost()
        
        navigationController?.navigationBar.barTintColor = UIColor(red:0.95, green:1.00, blue:1.00, alpha:1.0)
        aboveNavBarView.backgroundColor = UIColor(red:0.95, green:1.00, blue:1.00, alpha:1.0)
    }
    
    func showPost() {
        titleLabel.text = post.title
        descriptionLabel.text = post.description
        
        print(post.title)
        
        let imageWidth = post.imageWidth
        let imageHeight = post.imageHeight
        
        if post.type == "picture" {
            if let url = URL(string: post.imageURL) {
                postImageView.kf.setImage(with: url, placeholder: UIImage(named: "default"), options: nil, progressBlock: nil, completionHandler: nil)
            }
            
            let ratio = imageWidth / imageHeight
            let newHeight = self.view.frame.width / ratio
            
            imageViewHeightConstraint.constant = newHeight
        } else {
             imageViewHeightConstraint.constant = 0
        }
        
        
    }
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
