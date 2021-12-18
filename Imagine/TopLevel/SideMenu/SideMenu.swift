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
import DateToolsSwift

enum SideMenuButton {
    case toFriends
    case toSavedPosts
    case toVoting
    case toUser
    case toEULA
    case toPost
    case toComment
    case toChats
    case cancel
}

// Maybe create the currentUser here and pass it to the userfeedProfile
class SideMenu: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Elements
    var FeedTableView: FeedTableViewController?
    
    let blackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.alpha = 0
        
        
        return view
    }()
    
    let notificationTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = Constants.cellCornerRadius
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .none
        
        tableView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        tableView.layer.borderWidth = 1
        
        return tableView
    }()
    
    let notificationLabel = BaseLabel(text: Strings.sideMenuNotification, font: UIFont.standard(size: 14))
    
    let deleteAllNotificationsButton: DesignableButton = {
        let button = DesignableButton(title: Strings.sideMenuDeleteAll, font: UIFont.standard(size: 11), cornerRadius: 8, tintColor: .systemRed, backgroundColor: .systemBackground)
        button.alpha = 0
        
        return button
    }()
    
    let profileButton = DesignableButton()
    
    let profilePictureImageView: UIImageView = {
        let imgView = BaseImageView(image: Icons.defaultUser, contentMode: .scaleAspectFill)
        imgView.layer.cornerRadius = imgView.frame.height/2
        imgView.layoutIfNeeded()
        imgView.clipsToBounds = true
        
        return imgView
    }()
    
    let nameLabel = BaseLabel(font: UIFont.standard(with: .medium, size: 18), textAlignment: .center)
    
    // MARK: Chat, Friend, Saved UI
    
    let chatButton = DesignableButton(title: Strings.sideMenuChats, font: UIFont.standard(with: .medium, size: 16))
    
    let chatIconImageView: BaseImageView = {
        let iconImageView = BaseImageView(image: Icons.chat)
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
                
        return iconImageView
    }()
    
    lazy var chatStackView = BaseStackView(subviews: [chatIconImageView, chatButton], spacing: 15, axis: .horizontal, distribution: .fill)
    
    let chatCountLabel: UILabel = {
        let label = BaseLabel(textColor: .white, font: UIFont.standard(size: 10), textAlignment: .center)
        
        label.backgroundColor = Constants.blue
        label.clipsToBounds = true
        return label
    }()
    
    let friendsButton = DesignableButton(title: Strings.sideMenuFriends, font: UIFont.standard(with: .medium, size: 16))
    
    let friendsIconImageView: BaseImageView = {
        let iconImageView = BaseImageView(image: Icons.friends)
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
                        
        return iconImageView
    }()
    
    lazy var friendsStackView = BaseStackView(subviews: [friendsIconImageView, friendsButton], spacing: 15, axis: .horizontal, distribution: .fill)
    
    let invitationCountLabel: UILabel = {
        let label = BaseLabel(textColor: .white, font: UIFont.standard(size: 12), textAlignment: .center)
        label.backgroundColor = .red
        label.clipsToBounds = true
        
        return label
    }()
    
    let savedButton = DesignableButton(title: Strings.sideMenuSaved, font: UIFont.standard(with: .medium, size: 16))
    
    let savedIconImageView: BaseImageView = {
        let iconImageView = BaseImageView(image: Icons.save, alignmentInsets: UIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2))
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
                        
        return iconImageView
    }()
    
    lazy var savedPostsStackView = BaseStackView(subviews: [savedIconImageView, savedButton], spacing: 15, axis: .horizontal, distribution: .fill)

    lazy var verticalStackView = BaseStackView(subviews: [chatStackView, friendsStackView, savedPostsStackView], spacing: 15, axis: .vertical, distribution: .fillEqually)
    
    let settingButton = BaseButtonWithImage(image: Icons.settings, tintColor: .imagineColor)
    
    
    // MARK: - Variables
    
    var notifications = [Comment]()
    
    let reuseIdentifier = "notificationCell"
    let db = Firestore.firestore()
    let handyHelper = HandyHelper()
    
    let sideMenuView: UIView = {
        let vc = UIView()
        
        vc.backgroundColor = .systemBackground
        vc.layer.cornerRadius = 4
        
        return vc
    }()
    
    // MARK: - Init
    
    override init() {
        super.init()
        
        notificationTableView.register(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        
        if let window = UIApplication.keyWindow() {
            
            window.addSubview(blackView)
            blackView.frame = window.frame
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sideMenuDismissed)))
            
            window.addSubview(sideMenuView)
            
            addConstraints()
            
            let y = window.frame.height
            let sideMenuWidth : CGFloat = 260
            sideMenuView.frame = CGRect(x: -window.frame.width, y: 0, width: sideMenuWidth, height: y)
            
            let slideLeft = UISwipeGestureRecognizer(target: self, action: #selector(sideMenuDismissed))
            slideLeft.direction = .left
            window.addGestureRecognizer(slideLeft)
            
            sideMenuView.layoutIfNeeded()
        }
    }
    
    /// Show the SideMenu: Move the sideMenu over the FeedTableVC
    func showMenu() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.blackView.alpha = 1
            self.sideMenuView.frame = CGRect(x:0, y: 0, width: self.sideMenuView.frame.width, height: self.sideMenuView.frame.height)
            
        }, completion: { _ in
            self.sideMenuView.layoutSubviews()
        })
    }
    
    @objc func toUserProfileTapped() {
        print("To User")
        handleDismiss(sideMenuButton: .toUser, comment: nil)
    }
    
    @objc func toFriendsTapped() {
        print("To Friends")
        handleDismiss(sideMenuButton: .toFriends, comment: nil)
    }
    
    @objc func toVotingTapped() {
        print("To Voting")
        handleDismiss(sideMenuButton: .toVoting, comment: nil)
    }
    
    @objc func toChatsTapped() {
        handleDismiss(sideMenuButton: .toChats, comment: nil)
    }
    
    @objc func toSavedPostsTapped() {
        print("To Saved")
        handleDismiss(sideMenuButton: .toSavedPosts, comment: nil)
    }
    
    @objc func sideMenuDismissed() {
        handleDismiss(sideMenuButton: .cancel, comment: nil)
    }
    
    @objc func toEulaTapped() {
        print("To EUla")
        handleDismiss(sideMenuButton: .toEULA, comment: nil)
    }
    
    @objc func deleteAllTapped() {
        if let user = Auth.auth().currentUser {
            let ref = db.collection("Users").document(user.uid).collection("notifications").whereField("type", isEqualTo: "upvote")
            
            ref.getDocuments { (snap, err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    if let snap = snap {
                        self.hideDeleteAllButton()
                        for document in snap.documents {
                            let data = document.data()
                            if let postID = data["postID"] as? String {
                                self.handyHelper.deleteNotifications(type: .upvote, id: postID)
                                
                                self.notifications = self.notifications.filter{ $0.sectionItemID != postID }
                                self.notificationTableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func hideDeleteAllButton() {
        UIView.animate(withDuration: 0.5) {
            self.deleteAllNotificationsButton.alpha = 0
        }
    }
    
    func checkNotifications(invitations: Int, notifications: [Comment], newChats: Int) {
        if invitations != 0 {
            invitationCountLabel.text = String(invitations)
            invitationCountLabel.isHidden = false
        } else {
            invitationCountLabel.isHidden = true
        }
        
        if newChats != 0 {
            chatCountLabel.text = String(newChats)
            chatCountLabel.isHidden = false
        } else {
            chatCountLabel.isHidden = true
        }
        
        self.notifications.removeAll()
        self.notifications = notifications
        if notifications.count != 0 {
            self.deleteAllNotificationsButton.alpha = 1
        }
        
        self.notificationTableView.reloadData()
        
    }
    
    func handleDismiss(sideMenuButton: SideMenuButton, comment: Comment?) {    // Not just dismiss but also the presented options
        UIView.animate(withDuration: 0.5, animations: {
            self.blackView.alpha = 0
            
            if let window = UIApplication.keyWindow() {
                self.sideMenuView.frame = CGRect(x: -window.frame.width, y: 0, width: self.sideMenuView.frame.width, height: self.sideMenuView.frame.height)
            }
        }, completion: { (_) in
            
            switch sideMenuButton {
            case .cancel:
                print("Just dismiss Menu")
            default:
                self.FeedTableView?.sideMenuButtonTapped(whichButton: sideMenuButton, comment: comment)
                
            }
        })
    }
    
    
    
    // MARK: - Constraints
    func addConstraints() {
        verticalStackView.alignment = .leading
        verticalStackView.sizeToFit()
        
        sideMenuView.addSubview(verticalStackView)
        sideMenuView.addSubview(profileButton)
        sideMenuView.addSubview(profilePictureImageView)
        sideMenuView.addSubview(nameLabel)
        sideMenuView.addSubview(invitationCountLabel)
        sideMenuView.addSubview(chatCountLabel)
        sideMenuView.addSubview(notificationTableView)
        sideMenuView.addSubview(notificationLabel)
        sideMenuView.addSubview(deleteAllNotificationsButton)
        sideMenuView.addSubview(settingButton)
                
        profilePictureImageView.constrain(centerX: sideMenuView.centerXAnchor, top: sideMenuView.topAnchor, paddingTop: 60, width: 100, height: 100)
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height/2
        profilePictureImageView.layoutIfNeeded()
        
        profileButton.constrain(top: profilePictureImageView.topAnchor, leading: profilePictureImageView.leadingAnchor, bottom: nameLabel.bottomAnchor, trailing: profilePictureImageView.trailingAnchor)
        
        nameLabel.constrain(centerX: profilePictureImageView.centerXAnchor, top: profilePictureImageView.bottomAnchor, paddingTop: 10)
        
        let heightWidthOfSmallNumber:CGFloat = 16
        
        chatCountLabel.constrain(top: chatIconImageView.topAnchor, trailing: chatIconImageView.trailingAnchor, paddingTop: -4, paddingTrailing: 4, width: heightWidthOfSmallNumber, height: heightWidthOfSmallNumber)
        chatCountLabel.layer.cornerRadius = heightWidthOfSmallNumber/2
        chatCountLabel.layoutIfNeeded()
        
        invitationCountLabel.constrain(top: friendsIconImageView.topAnchor, trailing: friendsIconImageView.trailingAnchor, paddingTop: -4, paddingTrailing: 4, width: heightWidthOfSmallNumber, height: heightWidthOfSmallNumber)
        invitationCountLabel.layer.cornerRadius = heightWidthOfSmallNumber/2
        invitationCountLabel.layoutIfNeeded()
        
        verticalStackView.constrain(top: nameLabel.bottomAnchor, leading: sideMenuView.leadingAnchor, trailing: sideMenuView.trailingAnchor, paddingTop: 35, paddingLeading: 10, paddingTrailing: -10, height: 110)
        
        notificationLabel.constrain(top: verticalStackView.bottomAnchor, leading: sideMenuView.leadingAnchor, paddingTop: 35, paddingLeading: 10)
        
        notificationTableView.constrain(top: notificationLabel.bottomAnchor, leading: sideMenuView.leadingAnchor, trailing: sideMenuView.trailingAnchor, paddingTop: 5, paddingLeading: 10, paddingTrailing: -10)
        
        deleteAllNotificationsButton.constrain(bottom: notificationTableView.bottomAnchor, trailing: notificationTableView.trailingAnchor, paddingBottom: -2, paddingTrailing: -2)
                
        settingButton.constrain(top: notificationTableView.bottomAnchor, bottom: sideMenuView.bottomAnchor, trailing: sideMenuView.trailingAnchor, paddingTop: 15, paddingBottom: -30, paddingTrailing: -10)
        
        sideMenuView.layoutSubviews()
        sideMenuView.layoutIfNeeded()
        
        self.showUser()
        addTargetsForButtons()
    }
    
    func addTargetsForButtons() {
        chatButton.addTarget(self, action: #selector(toChatsTapped), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(toUserProfileTapped), for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(toFriendsTapped), for: .touchUpInside)
        savedButton.addTarget(self, action: #selector(toSavedPostsTapped), for: .touchUpInside)
        deleteAllNotificationsButton.addTarget(self, action: #selector(deleteAllTapped), for: .touchUpInside)
        settingButton.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
    }
    
    /// Get the user data and display it 
    func showUser() {
        if let user = Auth.auth().currentUser {
            if let url = user.photoURL {
                profilePictureImageView.sd_setImage(with: url, completed: nil)
            } else {
                profilePictureImageView.image = UIImage(named: "default-user")
            }
            nameLabel.text = user.displayName
            profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height/2
            profilePictureImageView.layoutIfNeeded()
        }
    }
    
    /// Remove the user from the UI after the user is logged out
    func removeUser() {
        profilePictureImageView.image = UIImage(named: "default-user")
        nameLabel.text = ""
        notifications.removeAll()
        notificationTableView.reloadData()
    }
    
    // - MARK: Notification TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = notifications[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? NotificationCell {
            
            cell.comment = comment
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let comment = notifications[indexPath.row]
        
        if let _ = comment.upvotes {
            // Vote notification
            self.handleDismiss(sideMenuButton: .toPost, comment: comment)
        } else {
            // Comment Notification
            self.handleDismiss(sideMenuButton: .toComment, comment: comment)
        }
    }
}
