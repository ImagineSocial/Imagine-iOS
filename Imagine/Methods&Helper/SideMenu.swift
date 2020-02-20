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
    
    let sideMenuView: UIView = {
        let vc = UIView()
        
        if #available(iOS 13.0, *) {
            vc.backgroundColor = .systemBackground
        } else {
            vc.backgroundColor = .white
        }
        
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
        sideMenuView.addSubview(disclaimerView)
        sideMenuView.addSubview(notificationTableView)
        
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
    
    
    
    
    
    func showMenu() {
        //show menu
        
            
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
        handleDismiss(sideMenuButton: .toUser, id: nil)
    }
    
    @objc func toFriendsTapped() {
        print("To Friends")
        handleDismiss(sideMenuButton: .toFriends, id: nil)
    }
    
    @objc func toVotingTapped() {
        print("To Voting")
        handleDismiss(sideMenuButton: .toVoting, id: nil)
    }
    
    @objc func toSavedPostsTapped() {
        print("To Saved")
        handleDismiss(sideMenuButton: .toSavedPosts, id: nil)
    }
    
    @objc func sideMenuDismissed() {
        handleDismiss(sideMenuButton: .cancel, id: nil)
    }
    
    @objc func toEulaTapped() {
        print("To EUla")
        handleDismiss(sideMenuButton: .toEULA, id: nil)
    }
    
    
    func checkNotifications(invitations: Int, notifications: [Comment]) {
        if invitations != 0 {
            smallNumberLabel.text = String(invitations)
            smallNumberLabel.isHidden = false
        } else {
            smallNumberLabel.isHidden = true
        }
                
        self.notifications.removeAll()
        self.notifications = notifications
        
        self.notificationTableView.reloadData()
        
    }
    
    func handleDismiss(sideMenuButton: SideMenuButton, id: String?) {    // Not just dismiss but also the presented options
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
                self.FeedTableView?.sideMenuButtonTapped(whichButton: sideMenuButton, id: id)
            }
        })
    }
    
    
    
    // -MARK: Constraints
    func addConstraints() {
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
        nameLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        profileButton.addTarget(self, action: #selector(toUserProfileTapped), for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(toFriendsTapped), for: .touchUpInside)
//        voteButton.addTarget(self, action: #selector(toVotingTapped), for: .touchUpInside)
        savedButton.addTarget(self, action: #selector(toSavedPostsTapped), for: .touchUpInside)
        eulaButton.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        addDisclaimer()
        
        friendsStackView.addArrangedSubview(friendsButton)
        verticalStackView.addArrangedSubview(friendsStackView)
//        votingStackView.addArrangedSubview(voteButton)
//        verticalStackView.addArrangedSubview(votingStackView)
        savedPostsStackView.addArrangedSubview(savedButton)
        verticalStackView.addArrangedSubview(savedPostsStackView)
        sideMenuView.addSubview(verticalStackView)
        
        let heightWidthOfSmallNumber:CGFloat = 16
        
        smallNumberLabel.trailingAnchor.constraint(equalTo: friendsStackView.trailingAnchor).isActive = true
        smallNumberLabel.centerYAnchor.constraint(equalTo: friendsStackView.centerYAnchor).isActive = true
        smallNumberLabel.heightAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallNumberLabel.widthAnchor.constraint(equalToConstant: heightWidthOfSmallNumber).isActive = true
        smallNumberLabel.layer.cornerRadius = heightWidthOfSmallNumber/2
        smallNumberLabel.layoutIfNeeded()
        
        verticalStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 10).isActive = true
        verticalStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 50).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -10).isActive = true
        verticalStackView.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        notificationTableView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 10).isActive = true
        notificationTableView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -10).isActive = true
//        notificationTableView.bottomAnchor.constraint(equalTo: disclaimerView.topAnchor, constant: 30).isActive = true
        notificationTableView.heightAnchor.constraint(equalToConstant: 175).isActive = true
        notificationTableView.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 30).isActive = true
        
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
    
    
    // MARK: Instantiate UI
    
    
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
        label.textColor = Constants.imagineColor
        
        return label
    }()
    
    let friendsButton: DesignableButton = {
        let btn = DesignableButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("Freunde", for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
//        if #available(iOS 13.0, *) {
//            btn.setTitleColor(.label, for: .normal)
//        } else {
//            btn.setTitleColor(.black, for: .normal)
//        }
        btn.setTitleColor(Constants.imagineColor, for: .normal)
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
        if #available(iOS 13.0, *) {
            iconImageView.tintColor = .label
        } else {
            iconImageView.tintColor = .black
        }
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
        btn.setTitle("Gesichert", for: .normal)
        btn.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 18)
//        if #available(iOS 13.0, *) {
//            btn.setTitleColor(.label, for: .normal)
//        } else {
//            btn.setTitleColor(.black, for: .normal)
//        }
        btn.setTitleColor(Constants.imagineColor, for: .normal)
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
        if #available(iOS 13.0, *) {
            iconImageView.tintColor = .label
        } else {
            iconImageView.tintColor = .black
        }
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
        button.setTitle("Einstellungen", for: .normal)
//        if #available(iOS 13.0, *) {
//            button.setTitleColor(.label, for: .normal)
//        } else {
//            button.setTitleColor(.black, for: .normal)
//        }
        button.setTitleColor(Constants.imagineColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans", size: 16)
        button.addTarget(self, action: #selector(toEulaTapped), for: .touchUpInside)
        
        return button
    }()
    
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "settings")
        logo.contentMode = .center
        if #available(iOS 13.0, *) {
            logo.tintColor = .label
        } else {
            logo.tintColor = .black
        }
        
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
            self.handleDismiss(sideMenuButton: .toPost, id: comment.postID)
        } else {
            // Comment Notification
            self.handleDismiss(sideMenuButton: .toComment, id: comment.postID)
        }
    }
    
    let notificationTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = 4
        tableView.layer.masksToBounds = true
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
}

class Comment {
    var title = ""
    var text = ""
    var createTimeString = ""
    var createTime = Date()
    var author = ""
    var postID = ""
    var upvotes: Votes?
    var user: User?
}



