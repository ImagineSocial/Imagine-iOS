//
//  SearchTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController {

    var postResults: [Post]?
    var userResults: [User]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(SearchUserCell.self, forCellReuseIdentifier: "SearchUserCell")
        tableView.register(SearchPostCell.self, forCellReuseIdentifier: "SearchPostCell")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let users = userResults {
            print("Das sind die Resultate: \(users.count)")
            return users.count
        }
        if let posts = postResults {
            print("Das sind die Resultate: \(posts.count)")
            return posts.count
        }
        
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let posts = postResults {
            let post = posts[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPostCell", for: indexPath) as? SearchPostCell {

                
                cell.post = post
                
                
                return cell
            }

        }
        
        if let users = userResults {
            let user = users[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserCell", for: indexPath) as? SearchUserCell {

                cell.user = user
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if let posts = postResults {
//            let post = posts[indexPath.row]
//
//            let feedVC = FeedTableViewController()
//            feedVC.goToPost(post: post)
////            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PostVC") as? PostViewController {
////                print("Post: jojo)")
////                viewController.post = post
////
////                present(viewController, animated: true, completion: nil)
////                if let navigator = navigationController {
////                    print("Post: jaja")
////                    navigator.pushViewController(viewController, animated: true)
////                }
////            }
//        }
//        if let users = userResults {
//            let user = users[indexPath.row]
//
//            let feedVC = FeedTableViewController()
//            feedVC.goToUser(user: user)
////            if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserVC") as? UserFeedTableViewController {
////                viewController.userUID = user.userUID
////                if let navigator = navigationController {
////                    navigator.pushViewController(viewController, animated: true)
////                }
////            }
//        }
//    }
    

    deinit {
        print("Jetzt wird gedeinit")
    }
    
}

class SearchUserCell: UITableViewCell {
    var user:User? {
        didSet {
            profilePictureImageView.image = nil
            nameLabel.text = "\(user!.name) \(user!.surname)"
            if let url = URL(string: user!.imageURL) {
                profilePictureImageView.sd_setImage(with: url, completed: nil)
            } else {
                profilePictureImageView.image = UIImage(named: "default-user")
            }
        }
    }
    
    private let nameLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        return lbl
    }()
    
    private let profilePictureImageView : UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "default-user"))
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 5
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(nameLabel)
        addSubview(profilePictureImageView)
        
        profilePictureImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        profilePictureImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        profilePictureImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        profilePictureImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        nameLabel.leadingAnchor.constraint(equalTo: profilePictureImageView.trailingAnchor, constant: 15).isActive = true
        nameLabel.topAnchor.constraint(equalTo: profilePictureImageView.topAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}




class SearchPostCell: UITableViewCell {
    
    var post:Post? {
        didSet {
            postImageView.image = nil
            titleLabel.text = post?.title
            if let url = URL(string: post!.imageURL) {
                postImageView.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    private let titleLabel : UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.textAlignment = .left
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 0
        lbl.minimumScaleFactor = 0.7
        return lbl
    }()
    
    private let postImageView : UIImageView = {
        let imgView = UIImageView(image: UIImage(named: "default"))
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 5
        imgView.clipsToBounds = true
        imgView.translatesAutoresizingMaskIntoConstraints = false
        return imgView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(titleLabel)
        addSubview(postImageView)
        
        postImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        postImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        postImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        postImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        titleLabel.leadingAnchor.constraint(equalTo: postImageView.trailingAnchor, constant: 15).isActive = true
        titleLabel.topAnchor.constraint(equalTo: postImageView.topAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: postImageView.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


