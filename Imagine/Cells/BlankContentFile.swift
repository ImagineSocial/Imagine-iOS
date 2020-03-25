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
                        self.descriptionLabel.text = "Du hast noch keine Chats. Schreibe jetzt deine Freunde an"
                    } else {
                        self.descriptionLabel.text = "Tausche dich hier mit deinen Mitmenschen aus"
                    }
                    
                case .friends:
                    self.pictureView.image = UIImage(named: "meetNewPeople")
                    self.descriptionLabel.text = "Hier werden dir deine Freunde angezeigt"
                case .savedPicture:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Hier werden deine gespeicherten Beiträge gesammelt"
                case .ownProfile:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Du hast noch keine Beiträge hochgeladen"
                case .userProfile:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Dieser User hat noch keine Beiträge hochgeladen"
                case .postsOfFacts:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Es sind noch keine Beiträge zu diesem Thema zu finden"
                case .search:
                    self.pictureView.isHidden = true
                    self.descriptionLabel.isHidden = true
                }
            }
        }
    }
    
}
