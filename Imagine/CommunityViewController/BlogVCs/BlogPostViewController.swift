//
//  BlogPostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.08.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class BlogPostViewController: UIViewController {

    var blogPost: BlogPost?
    var info: Info?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subHeaderLabel: UILabel!
    @IBOutlet weak var blogImageView: UIImageView!
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setPost()
    }
    
    func setPost() {
        if let post = blogPost {
            headerLabel.text = post.title
            subHeaderLabel.text = post.subtitle
            bodyTextView.text = post.description
            
            if let url = URL(string: post.imageURL) {
                blogImageView.sd_setImage(with: url, completed: nil)
            } else {
                //Just the Imagine Sign
            }
            
        } else {
            //Just Information for the InfoVC
            if let info = info {
                headerLabel.text = info.title
                if let image = info.image {
                    blogImageView.image = image
                } else {
                    blogImageView.isHidden = true
                    imageViewHeightConstraint.constant = 20
                }
                bodyTextView.text = info.description
            }
        }
    }
    
    

}
