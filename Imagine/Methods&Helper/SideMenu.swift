//
//  SideMenu.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase


enum SideMenuButton {
    case toFriends
    case toSavedPosts
    case toVoting
    case toUser
    case cancel
}

class SideMenuButtons {
    
}

class SideMenu: NSObject {
    
    var FeedTableView:FeedTableViewController?
    
    let blackView = UIView()
    
    let sideMenuView: UIView = {
        let vc = UIView()
        vc.backgroundColor = UIColor.white
        return vc
    }()
    
//    override init() {
//        super.init()
//
//        if let window = UIApplication.shared.keyWindow {
//        window.addSubview(blackView)
//        window.addSubview(sideMenuView)
//        sideMenuView.addSubview(profileButton)
//
//        verticalStackView.addArrangedSubview(friendsStackView)
//        verticalStackView.addArrangedSubview(votingStackView)
//        verticalStackView.addArrangedSubview(savedPostsStackView)
//        sideMenuView.addSubview(verticalStackView)
//        }
//        }
    
    
    
    @objc func toUserProfileTapped() {
        print("To User")
        handleDismiss(sideMenuButton: .toUser)
    }
    
    @objc func toFriendsTapped() {
        print("To Friends")
        handleDismiss(sideMenuButton: .toFriends)
    }
    
    @objc func toVotingTapped() {
        print("To Voting")
        handleDismiss(sideMenuButton: .toVoting)
    }
    
    @objc func toSavedPostsTapped() {
        print("To Saved")
        handleDismiss(sideMenuButton: .toSavedPosts)
    }
    
    @objc func sideMenuDismissed() {
        handleDismiss(sideMenuButton: .cancel)
    }
    
    let cellId = "cellId"
    let settingCellHeight: CGFloat = 60
    
//    let settings: [Setting] = {
//        return [Setting(name: "Chat with User", imageName: "chat", type: .other), Setting(name: "Blockieren", imageName: "collaboration", type: .other), Setting(name: "Cancel", imageName: "camera", type: .cancel)]
//    }()
    
    func showSettings() {
        //show menu
        
        if let window = UIApplication.shared.keyWindow {
            
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sideMenuDismissed)))
            
            window.addSubview(blackView)
            window.addSubview(sideMenuView)
            sideMenuView.addSubview(profileButton)
            sideMenuView.addSubview(profilePictureImageView)
            sideMenuView.addSubview(nameLabel)
            
            profilePictureImageView.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
            profilePictureImageView.topAnchor.constraint(equalTo: sideMenuView.topAnchor, constant: 50).isActive = true
            profilePictureImageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
            profilePictureImageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height/2
            profilePictureImageView.layoutIfNeeded()
            
            profileButton.leadingAnchor.constraint(equalTo: profilePictureImageView.leadingAnchor).isActive = true
            profileButton.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
            profileButton.widthAnchor.constraint(equalTo: profilePictureImageView.widthAnchor).isActive = true
            profileButton.heightAnchor.constraint(equalTo: profilePictureImageView.heightAnchor).isActive = true
            
            nameLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 15).isActive = true
            nameLabel.centerXAnchor.constraint(equalTo: profilePictureImageView.centerXAnchor).isActive = true
            
            profileButton.addTarget(self, action: #selector(toUserProfileTapped), for: .touchUpInside)
            friendsButton.addTarget(self, action: #selector(toFriendsTapped), for: .touchUpInside)
            voteButton.addTarget(self, action: #selector(toVotingTapped), for: .touchUpInside)
            savedButton.addTarget(self, action: #selector(toSavedPostsTapped), for: .touchUpInside)
            
            
            friendsStackView.addArrangedSubview(friendsButton)
            verticalStackView.addArrangedSubview(friendsStackView)
            votingStackView.addArrangedSubview(voteButton)
            verticalStackView.addArrangedSubview(votingStackView)
            savedPostsStackView.addArrangedSubview(savedButton)
            verticalStackView.addArrangedSubview(savedPostsStackView)
            sideMenuView.addSubview(verticalStackView)
            
            verticalStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 25).isActive = true
            verticalStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 50).isActive = true
            verticalStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: 25).isActive = true
            verticalStackView.heightAnchor.constraint(equalToConstant: 125).isActive = true
            
            
            
            
            let y = window.frame.height
            let sideMenuWidth : CGFloat = 260
            sideMenuView.frame = CGRect(x: -window.frame.width, y: 0, width: sideMenuWidth, height: y)
            sideMenuView.layer.cornerRadius = 4
            
            
            blackView.frame = window.frame
            blackView.alpha = 0
            
            sideMenuView.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackView.alpha = 1
                self.sideMenuView.frame = CGRect(x:0, y: 0, width: self.sideMenuView.frame.width, height: self.sideMenuView.frame.height)
                
            }, completion: nil)
        }
    }
    
    func handleDismiss(sideMenuButton: SideMenuButton) {    // Not just dismiss but also the presented options
        UIView.animate(withDuration: 0.5, animations: {
            self.blackView.alpha = 0
            
            if let window = UIApplication.shared.keyWindow {
                self.sideMenuView.frame = CGRect(x: -window.frame.width, y: 0, width: self.sideMenuView.frame.width, height: self.sideMenuView.frame.height)
            }
        }, completion: { (_) in
            
            switch sideMenuButton {
            case .cancel:
                print("Just dismiss Menu")
            default:
                self.FeedTableView?.sideMenuButtonTapped(whichButton: sideMenuButton)
            }
            
            
        })
    }

    
    
    let profileButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    let profilePictureImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        
        if let user = Auth.auth().currentUser {
            if let url = user.photoURL {
                imgView.sd_setImage(with: url, completed: nil)
            }
        } else {
            imgView.image = UIImage(named: "default-user")
        }
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = imgView.frame.height/2
        imgView.layoutIfNeeded()
        imgView.clipsToBounds = true
        
        
        return imgView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        if let user = Auth.auth().currentUser {
            label.text = user.displayName
        } else {
            label.text = "Mein Name"
        }
        label.font = UIFont.systemFont(ofSize: 18)
        return label
    }()
    
    let friendsButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Freunde", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()
    
    let friendsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = .horizontal
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: "people")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        stackView.addArrangedSubview(iconImageView)
        
        return stackView
    }()
    
    let voteButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Abstimmungen", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()
    
    let votingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = .horizontal
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: "handshake")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        stackView.addArrangedSubview(iconImageView)
        
        return stackView
    }()
    
    let savedButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Saved", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }()
    
    let savedPostsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = .horizontal
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: "save")
        iconImageView.tintColor = .black
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        stackView.addArrangedSubview(iconImageView)
        
        return stackView
    }()
    
    
    let verticalStackView : UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.fillEqually
        stackView.alignment = UIStackView.Alignment.fill
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        return stackView
    }()
}

