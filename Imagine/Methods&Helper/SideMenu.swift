//
//  SideMenu.swift
//  Imagine
//
//  Created by Malte Schoppe on 14.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

enum SideMenuButton {
    case toFriends
    case toSavedPosts
    case toVoting
    case toUser
    case cancel
}

//Maybe create the currentUser here and pass it to the userfeedProfile
class SideMenu: NSObject {
    
    var FeedTableView:FeedTableViewController?
    
    let blackView = UIView()
    
    let sideMenuView: UIView = {
        let vc = UIView()
        vc.backgroundColor = UIColor.white
        return vc
    }()
    
    
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
    
    
    func checkInvitations(invites: Int) {
        if invites != 0 {
            smallNumberLabel.text = String(invites)
            smallNumberLabel.isHidden = false
        } else {
            smallNumberLabel.isHidden = true
        }
    }
    
    func showSettings() {
        //show menu
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(blackView)
            
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sideMenuDismissed)))
            blackView.frame = window.frame
            blackView.alpha = 0
            
            
            window.addSubview(sideMenuView)
            sideMenuView.addSubview(profileButton)
            sideMenuView.addSubview(profilePictureImageView)
            sideMenuView.addSubview(nameLabel)
            sideMenuView.addSubview(smallNumberLabel)
            sideMenuView.addSubview(disclaimerView)
            
            addConstraints()
            
            let y = window.frame.height
            let sideMenuWidth : CGFloat = 260
            sideMenuView.frame = CGRect(x: -window.frame.width, y: 0, width: sideMenuWidth, height: y)
            sideMenuView.layer.cornerRadius = 4
            
            let slideLeft = UISwipeGestureRecognizer(target: self, action: #selector(sideMenuDismissed))
            slideLeft.direction = .left
            window.addGestureRecognizer(slideLeft)
            
            
            sideMenuView.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackView.alpha = 1
                self.sideMenuView.frame = CGRect(x:0, y: 0, width: self.sideMenuView.frame.width, height: self.sideMenuView.frame.height)
                
            }, completion: { (_) in
                
                self.sideMenuView.layoutSubviews()
            })
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
    
    func addConstraints() {
        profilePictureImageView.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: sideMenuView.topAnchor, constant: 50).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 110).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 110).isActive = true
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
//        voteButton.addTarget(self, action: #selector(toVotingTapped), for: .touchUpInside)
        savedButton.addTarget(self, action: #selector(toSavedPostsTapped), for: .touchUpInside)
        
        
        friendsStackView.addArrangedSubview(friendsButton)
        verticalStackView.addArrangedSubview(friendsStackView)
//        votingStackView.addArrangedSubview(voteButton)
//        verticalStackView.addArrangedSubview(votingStackView)
        savedPostsStackView.addArrangedSubview(savedButton)
        verticalStackView.addArrangedSubview(savedPostsStackView)
        sideMenuView.addSubview(verticalStackView)
        
        let heightWidthOfSmallNumber:CGFloat = 22
        
        smallNumberLabel.trailingAnchor.constraint(equalTo: friendsStackView.trailingAnchor).isActive = true
        smallNumberLabel.centerYAnchor.constraint(equalTo: friendsStackView.centerYAnchor).isActive = true
        smallNumberLabel.heightAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallNumberLabel.widthAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallNumberLabel.layer.cornerRadius = heightWidthOfSmallNumber/2
        smallNumberLabel.layoutIfNeeded()
        
        verticalStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 20).isActive = true
        verticalStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 50).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -10).isActive = true
        verticalStackView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        disclaimerView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 30).isActive = true
        disclaimerView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -30).isActive = true
        disclaimerView.bottomAnchor.constraint(equalTo: sideMenuView.bottomAnchor, constant: -15).isActive = true
        disclaimerView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.sideMenuView.layoutSubviews()
        self.sideMenuView.layoutIfNeeded()
        
        self.showUser()
    }
    
    func showUser() {
        if let user = Auth.auth().currentUser {
            if let url = user.photoURL {
                profilePictureImageView.sd_setImage(with: url, completed: nil)
                nameLabel.text = user.displayName
                
                profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height/2
                profilePictureImageView.layoutIfNeeded()
            }
        }
    }
    
    
    let profileButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    let profilePictureImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = imgView.frame.height/2
        imgView.layoutIfNeeded()
        imgView.clipsToBounds = true
        
        return imgView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        return label
    }()
    
    let friendsButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Freunde", for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
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
    
    let smallNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .red
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont(name: "IBMPlexSans", size: 16)
        label.clipsToBounds = true
        return label
    }()
    
//    let voteButton: DesignableButton = {
//        let btn = DesignableButton()
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        btn.setTitle("Abstimmungen", for: .normal)
//        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
//        btn.setTitleColor(.lightGray, for: .normal)
//        return btn
//    }()
//
//    let votingStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.axis  = .horizontal
//        stackView.spacing   = 5
//        stackView.sizeToFit()
//
//        let iconImageView = UIImageView()
//        iconImageView.translatesAutoresizingMaskIntoConstraints = false
//        iconImageView.image = UIImage(named: "handshake")
//        iconImageView.contentMode = .scaleAspectFit
//        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
//        iconImageView.alpha = 0.5
//
//        stackView.addArrangedSubview(iconImageView)
//
//        return stackView
//    }()
    
    let savedButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Saved", for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
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
    
    let disclaimerView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Nutzungsbedingungen", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 12)
        
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "settings")
        logo.contentMode = .center
        
        view.addSubview(logo)
        logo.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        logo.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        logo.widthAnchor.constraint(equalToConstant: 15).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        view.addSubview(button)
        button.leadingAnchor.constraint(equalTo: logo.trailingAnchor).isActive = true
        button.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        button.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        return view
    }()
}

