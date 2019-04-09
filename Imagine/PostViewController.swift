//
//  PostViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 10.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Kingfisher
import SDWebImage


class PostViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var OPNameLabel: UILabel!
    @IBOutlet weak var postDateLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    var post = Post()
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        showPost()
    }
    
    func showPost() {
        titleLabel.text = post.title
        descriptionLabel.text = post.description
        postDateLabel.text = post.createTime
        
        profilePictureImageView.layer.masksToBounds = true
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.width/2
        if let url = URL(string: post.originalPosterImageURL) {
            profilePictureImageView.sd_setImage(with: url, completed: nil)
        }
        OPNameLabel.text = post.originalPosterName
        
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
        
        contentView.heightAnchor.constraint(equalToConstant: 1000)
        scrollView.heightAnchor.constraint(equalToConstant: 1000)
        
    }
    
    @IBAction func dismissPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func userTapped(_ sender: Any) {
        
        if post.originalPosterUID != "" {
            performSegue(withIdentifier: "toUserSegue", sender: post.originalPosterUID)
        } else {
            print("Kein User zu finden!")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextVC = segue.destination as? UserProfileViewController {
            if let OPUID = sender as? String {
                nextVC.userUID = OPUID
            } else {
                print("Irgendwas will der hier nicht übertragen")
            }
        }
    }
    
}
