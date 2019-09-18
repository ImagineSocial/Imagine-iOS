//
//  BlankContentFile.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.09.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

enum BlankCellType {
    case savedPicture
    case friends
    case chat
    case ownProfile
    case userProfile
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
                        self.descriptionLabel.text = "Tausch dich hier mit deinen Mitmenschen aus"
                    }
                    
                case .friends:
                    self.pictureView.image = UIImage(named: "meetNewPeople")
                    self.descriptionLabel.text = "Hier werden deine Freunde angezeigt"
                case .savedPicture:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Speichere hier deine Lieblings Posts"
                case .ownProfile:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Du hast noch keine Posts hochgeladen"
                case .userProfile:
                    self.pictureView.image = UIImage(named: "savePostImage")
                    self.descriptionLabel.text = "Dieser User hat noch keine Posts hochgeladen"
                }
            }
        }
    }
    
}
