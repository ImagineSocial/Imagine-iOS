//
//  BlankContentFile.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

enum BlankCellType {
    case savedPicture
    case friends
    case chat
    case ownProfile
    case userProfile
    case postsOfFacts
    case search
}

class BlankContentCell: UITableViewCell {
    
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var type:BlankCellType? {
        didSet {
            if let type = type {
                switch type {
                case .chat:
                    self.pictureView.image = UIImage(named: "chatWithPeople")
                    
                    if let _ = Auth.auth().currentUser {
                        self.descriptionLabel.text = NSLocalizedString("blank_content_chats", comment: "no chats yet")
                    } else {
                        self.descriptionLabel.text = "Tausche dich hier mit deinen Mitmenschen aus"
                    }
                    
                case .friends:
                    self.pictureView.image = UIImage(named: "meetNewPeople")
                    self.descriptionLabel.text = NSLocalizedString("blank_content_friends", comment: "no friends yet")
                case .savedPicture:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = NSLocalizedString("blank_content_saved", comment: "no saved yet")
                case .ownProfile:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = NSLocalizedString("blank_content_ownPosts", comment: "no posts yet")
                case .userProfile:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = NSLocalizedString("blank_content_stranger_posts", comment: "no posts yet")
                case .postsOfFacts:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = NSLocalizedString("blank_content_topic_feed", comment: "no posts yet")
                case .search:
                    self.pictureView.isHidden = true
                    self.descriptionLabel.isHidden = true
                }
            }
        }
    }
    
}
