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
    case toEULA
    case toPost
    case toComment
    case toChats
    case cancel
}

//Maybe create the currentUser here and pass it to the userfeedProfile
class SideMenu: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var FeedTableView:FeedTableViewController?
    
    let blackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.alpha = 0
        
        
        return view
    }()
    
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
    
    
    override init() {
        super.init()
        
        notificationTableView.register(UINib(nibName: "NotificationCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        
        notificationTableView.delegate = self
        notificationTableView.dataSource = self
        
        if let window = UIApplication.shared.keyWindow {
            
            window.addSubview(blackView)
            blackView.frame = window.frame
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sideMenuDismissed)))
            
            
            window.addSubview(sideMenuView)
            sideMenuView.addSubview(profileButton)
            sideMenuView.addSubview(profilePictureImageView)
            sideMenuView.addSubview(nameLabel)
            sideMenuView.addSubview(smallNumberLabel)
            sideMenuView.addSubview(smallChatNumberLabel)
            sideMenuView.addSubview(disclaimerView)
            sideMenuView.addSubview(notificationTableView)
            sideMenuView.addSubview(notificationLabel)
            sideMenuView.addSubview(badgeStackView)
            sideMenuView.addSubview(deleteAllNotificationsButton)
            
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
    
    ///Show the SideMenu: Move the sideMenu over the FeedTableVC
    func showMenu() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            
            self.blackView.alpha = 1
            self.sideMenuView.frame = CGRect(x:0, y: 0, width: self.sideMenuView.frame.width, height: self.sideMenuView.frame.height)
            
        }, completion: { (_) in
            
            self.sideMenuView.layoutSubviews()
        })
        //        }
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
            smallNumberLabel.text = String(invitations)
            smallNumberLabel.isHidden = false
        } else {
            smallNumberLabel.isHidden = true
        }
        
        if newChats != 0 {
            smallChatNumberLabel.text = String(newChats)
            smallChatNumberLabel.isHidden = false
        } else {
            smallChatNumberLabel.isHidden = true
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
            
            if let window = UIApplication.shared.keyWindow {
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
    
    
    
    // MARK:- Constraints
    func addConstraints() {
        addTargetsForButtons()
        
        profilePictureImageView.centerXAnchor.constraint(equalTo: sideMenuView.centerXAnchor).isActive = true
        profilePictureImageView.topAnchor.constraint(equalTo: sideMenuView.topAnchor, constant: 50).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 110).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 110).isActive = true
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height/2
        profilePictureImageView.layoutIfNeeded()
        
        profileButton.leadingAnchor.constraint(equalTo: profilePictureImageView.leadingAnchor).isActive = true
        profileButton.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
        profileButton.trailingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor).isActive = true
        profileButton.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        
        nameLabel.topAnchor.constraint(equalTo: profilePictureImageView.bottomAnchor, constant: 15).isActive = true
        nameLabel.centerXAnchor.constraint(equalTo: profilePictureImageView.centerXAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        badgeStackView.addArrangedSubview(firstBadgeImageView)
        badgeStackView.addArrangedSubview(secondBadgeImageView)
        
        badgeStackView.leadingAnchor.constraint(equalTo: profilePictureImageView.leadingAnchor).isActive = true
        badgeStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        badgeStackView.heightAnchor.constraint(equalToConstant: 25).isActive = true
        badgeStackView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        
        addDisclaimer()
        
        chatStackView.addArrangedSubview(chatButton)
        verticalStackView.addArrangedSubview(chatStackView)
        friendsStackView.addArrangedSubview(friendsButton)
        verticalStackView.addArrangedSubview(friendsStackView)
        //        votingStackView.addArrangedSubview(voteButton)
        //        verticalStackView.addArrangedSubview(votingStackView)
        savedPostsStackView.addArrangedSubview(savedButton)
        verticalStackView.addArrangedSubview(savedPostsStackView)
        sideMenuView.addSubview(verticalStackView)
        
        let heightWidthOfSmallNumber:CGFloat = 16
        
        smallChatNumberLabel.trailingAnchor.constraint(equalTo: chatStackView.trailingAnchor).isActive = true
        smallChatNumberLabel.centerYAnchor.constraint(equalTo: chatStackView.centerYAnchor).isActive = true
        smallChatNumberLabel.heightAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallChatNumberLabel.widthAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallChatNumberLabel.layer.cornerRadius = heightWidthOfSmallNumber/2
        smallChatNumberLabel.layoutIfNeeded()
        
        smallNumberLabel.trailingAnchor.constraint(equalTo: friendsStackView.trailingAnchor).isActive = true
        smallNumberLabel.centerYAnchor.constraint(equalTo: friendsStackView.centerYAnchor).isActive = true
        smallNumberLabel.heightAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallNumberLabel.widthAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallNumberLabel.layer.cornerRadius = heightWidthOfSmallNumber/2
        smallNumberLabel.layoutIfNeeded()
        
        verticalStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 10).isActive = true
        verticalStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 50).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -10).isActive = true
        verticalStackView.heightAnchor.constraint(equalToConstant: 115).isActive = true
        
        notificationTableView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 5).isActive = true
        notificationTableView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -5).isActive = true
        //        notificationTableView.bottomAnchor.constraint(equalTo: disclaimerView.topAnchor, constant: 30).isActive = true
//        notificationTableView.heightAnchor.constraint(equalToConstant: 175).isActive = true
        notificationTableView.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 40).isActive = true
        notificationTableView.bottomAnchor.constraint(equalTo: disclaimerView.topAnchor, constant: -30).isActive = true
        
        deleteAllNotificationsButton.trailingAnchor.constraint(equalTo: notificationTableView.trailingAnchor, constant: -2).isActive = true
        deleteAllNotificationsButton.bottomAnchor.constraint(equalTo: notificationTableView.bottomAnchor, constant: -2).isActive = true
        deleteAllNotificationsButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        deleteAllNotificationsButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        notificationLabel.leadingAnchor.constraint(equalTo: notificationTableView.leadingAnchor).isActive = true
        notificationLabel.bottomAnchor.constraint(equalTo: notificationTableView.topAnchor, constant: -5).isActive = true
        
        disclaimerView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 20).isActive = true
        disclaimerView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -50).isActive = true
        disclaimerView.bottomAnchor.constraint(equalTo: sideMenuView.bottomAnchor, constant: -25).isActive = true
        disclaimerView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.sideMenuView.layoutSubviews()
        self.sideMenuView.layoutIfNeeded()
        
        self.showUser()
    }
    
    func addDisclaimer() {
        
        disclaimerView.addSubview(logo)
        logo.leadingAnchor.constraint(equalTo: disclaimerView.leadingAnchor, constant: 10).isActive = true
        logo.centerYAnchor.constraint(equalTo: disclaimerView.centerYAnchor).isActive = true
        logo.widthAnchor.constraint(equalToConstant: 15).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        disclaimerView.addSubview(eulaButton)
        eulaButton.leadingAnchor.constraint(equalTo: logo.trailingAnchor).isActive = true
        eulaButton.topAnchor.constraint(equalTo: disclaimerView.topAnchor).isActive = true
        eulaButton.trailingAnchor.constraint(equalTo: disclaimerView.trailingAnchor).isActive = true
        eulaButton.heightAnchor.constraint(equalTo: disclaimerView.heightAnchor).isActive = true
    }
    
    func addTargetsForButtons() {   // Doesnt work when I add the target on creation of the buttons
        chatButton.addTarget(self, action: #selector(toChatsTapped), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(toUserProfileTapped), for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(toFriendsTapped), for: .touchUpInside)
        //        voteButton.addTarget(self, action: #selector(toVotingTapped), for: .touchUpInside)
        savedButton.addTarget(self, action: #selector(toSavedPostsTapped), for: .touchUpInside)
        eulaButton.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        deleteAllNotificationsButton.addTarget(self, action: #selector(deleteAllTapped), for: .touchUpInside)
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
       
            let userObject = User(userID: user.uid)
            userObject.getBadges { (badges) in
                for badge in badges {
                    if badge == "first500" {
                        self.firstBadgeImageView.image = UIImage(named: "First500Badge")
                    } else if badge == "mod" {
                        self.secondBadgeImageView.image = UIImage(named: "ModBadge")
                    }
                }
            }
        }
    }
    
    /// Remove the user from the UI after the user is logged out
    func removeUser() {
        profilePictureImageView.image = UIImage(named: "default-user")
        nameLabel.text = ""
        notifications.removeAll()
        notificationTableView.reloadData()
    }
    
    // MARK:- Instantiate UI
    
    let notificationTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = 8
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .none
        
        tableView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        tableView.layer.borderWidth = 1
        
        return tableView
    }()
    
    let notificationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 14)
        label.text = NSLocalizedString("sideMenu_notifications_label", comment: "notifications:")
        label.tintColor = .label
        
        return label
    }()
    
    let deleteAllNotificationsButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("sideMenu_notifications_delete_label", comment: "delete all"), for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 11)
        button.alpha = 0
        button.cornerRadius = 8
        button.backgroundColor = .systemBackground
        
        return button
    }()
    
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
        imgView.image = UIImage(named: "default-user")
        
        return imgView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        label.textColor = .imagineColor
        
        return label
    }()
    
    //MARK:- BadgeUI
    let badgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 3
        
        return stack
    }()
    
    let firstBadgeImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFit
        imgView.image = nil
        imgView.tintColor = .label
        
        return imgView
    }()
    
    let secondBadgeImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFit
        imgView.image = nil
        imgView.tintColor = .label
        
        return imgView
    }()
    
    //MARK:- Chat, Friend, Saved UI
    let chatButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(NSLocalizedString("sideMenu_chats_label", comment: "chats"), for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        btn.setTitleColor(.imagineColor, for: .normal)
        
        return btn
    }()
    
    let chatStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = .horizontal
        stackView.distribution = .fill
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: "Chats")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .label
        iconImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        
        stackView.addArrangedSubview(iconImageView)
        
        return stackView
    }()
    
    let smallChatNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor(red: 23/255, green: 145/255, blue: 255/255, alpha: 1)
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont(name: "IBMPlexSans", size: 12)
        label.clipsToBounds = true
        return label
    }()
    
    let friendsButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(NSLocalizedString("sideMenu_friends_label", comment: "friends"), for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        btn.setTitleColor(.imagineColor, for: .normal)
        
        return btn
    }()
    
    let friendsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = .horizontal
        stackView.distribution = .fill
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: "people")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .label
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
        label.font = UIFont(name: "IBMPlexSans", size: 12)
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
        btn.setTitle(NSLocalizedString("sideMenu_saved_label", comment: "saved"), for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
        btn.setTitleColor(.imagineColor, for: .normal)
        return btn
    }()
    
    let savedPostsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis  = .horizontal
        stackView.distribution = .fill
        stackView.spacing   = 5
        stackView.sizeToFit()
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(named: "save")
        iconImageView.tintColor = .label
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
        
        return view
    }()
    
    let eulaButton:DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("sideMenu_setting_label", comment: "settings"), for: .normal)
        button.setTitleColor(.imagineColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
        button.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        return button
    }()
    
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "settings")
        logo.contentMode = .center
        logo.tintColor = .label
        
        return logo
    }()
    
    
    // - MARK: TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
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
        
        return 60
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


