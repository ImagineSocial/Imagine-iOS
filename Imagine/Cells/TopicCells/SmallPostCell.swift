//
//  DIYCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class SmallPostCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var postTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var postImageViewWidthConstraint: NSLayoutConstraint!
    
    
    let db = Firestore.firestore()
    let postHelper = PostHelper()
    
    var postTitle: String? {
        didSet {
            titleLabel.text = postTitle!
        }
    }
    
    var postID: String? {
        didSet {
            let ref = db.collection("Posts").document(postID!)
            
            ref.getDocument { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        if let post = self.postHelper.addThePost(document: snap, forFeed: false){
                            
                            self.post = post
                        }
                    }
                }
            }
        }
    }
    
    var post: Post? {
        didSet {
            guard let post = post else { return }
            
            if post.type == .picture {
                if let url = URL(string: post.imageURL) {
                    cellImageView.sd_setImage(with: url, completed: nil)
                } else {
                    cellImageView.image = UIImage(named: "about")
                }
                
            } else if post.type == .GIF {
                cellImageView.image = UIImage(named: "GIFIcon")
            } else if post.type == .link {
                cellImageView.image = UIImage(named: "translate")
            } else {
                postImageViewWidthConstraint.constant = 0
            }
            
            postTitleLabel.text = post.title
            descriptionLabel.text = post.description
        }
    }
    
    
    override func awakeFromNib() {
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .secondarySystemBackground
        } else {
            contentView.backgroundColor = .ios12secondarySystemBackground
        }
        
        contentView.layer.cornerRadius = 6
        cellImageView.layer.cornerRadius = 4
        backgroundColor = .clear
    }
    
}
