//
//  UserFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class UserFeedTableViewController: UITableViewController, PostCellDelegate {

    var posts = [Post]()
    var userUID = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewSetup()
        
        tableView.estimatedRowHeight = 400
        
    }
    
    func setUID(UID: String) {
        userUID = UID
        print("Das ist die UID: \(UID)")
        
        getPosts()
    }
    
    func tableViewSetup() {
        let refreshControl = UIRefreshControl()
        tableView.separatorStyle = .none
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        }
        
        refreshControl.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Moment!")
        
        self.tableView.addSubview(refreshControl)
    }
    
    
    @objc func getPosts() {
        UserPostHelper().getPosts(userUID: userUID) { (posts) in
            self.posts = posts
            self.tableView.reloadData()
            
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        performSegue(withIdentifier: "showPost", sender: post)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        
        if post.type == "repost" {  // Wenn es ein Repost ist wird die RepostCell genommen
            
             let identifier = "NibRepostCell"
             
             //Vielleicht noch absichern?!! Weiß aber nicht wie!
             tableView.register(UINib(nibName: "RePostTableViewCell", bundle: nil), forCellReuseIdentifier: identifier)
             
             if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell  {
                
                repostCell.cellImageView.image = nil
                
                repostCell.originalTitleLabel.text = nil
                repostCell.translatedTitleLabel.text = nil
                
                repostCell.OGPostView.layer.borderWidth = 1
                repostCell.OGPostView.layer.borderColor = UIColor.black.cgColor
                
                let repostDocumentID = post.OGRepostDocumentID
                
                if let repost = posts.first(where: {$0.documentID == repostDocumentID}) {
                    repostCell.originalTitleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    repostCell.translatedTitleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    repostCell.translatedTitleLabel.text = post.title
                    repostCell.originalTitleLabel.text = repost.title
                    repostCell.originalCreateDateLabel.text = repost.createTime
                    
                    if let url = URL(string: repost.imageURL) {
                        if let repostCellImageView = repostCell.cellImageView {
                            
                            repostCellImageView.isHidden = false      // Check ich nicht, aber geht!
                            repostCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                            repostCellImageView.layer.cornerRadius = 5
                            repostCellImageView.clipsToBounds = true
                        }
                    }
                    
                    //Reportview einstellen
                    
                    if repost.report == "normal" {
                        
                        repostCell.reportViewHeightConstraint.constant = 0
                        repostCell.reportViewButton.isHidden = true
                        
                    } else {
                        
                        repostCell.reportViewHeightConstraint.constant = 24
                        repostCell.reportViewButton.isHidden = false
                        
                        switch repost.report {
                        case "opinion":
                            repostCell.reportViewLabel.text = "   Meinung, kein Fakt"
                            repostCell.reportView.backgroundColor = UIColor(red:0.27, green:0.00, blue:0.01, alpha:1.0)
                        case "sensationalism":
                            repostCell.reportViewLabel.text = "   Sensationalismus"
                            repostCell.reportView.backgroundColor = UIColor(red:0.36, green:0.00, blue:0.01, alpha:1.0)
                        case "circlejerk":
                            repostCell.reportViewLabel.text = "   Circlejerk"
                            repostCell.reportView.backgroundColor = UIColor(red:0.58, green:0.04, blue:0.05, alpha:1.0)
                        case "pretentious":
                            repostCell.reportViewLabel.text = "   Angeberisch"
                            repostCell.reportView.backgroundColor = UIColor(red:0.83, green:0.05, blue:0.07, alpha:1.0)
                        case "edited":
                            repostCell.reportViewLabel.text = "   Nachbearbeitet"
                            repostCell.reportView.backgroundColor = UIColor(red:1.00, green:0.40, blue:0.36, alpha:1.0)
                        case "ignorant":
                            repostCell.reportViewLabel.text = "   Schwarz-Weiß-Denken"
                            repostCell.reportView.backgroundColor = UIColor(red:1.00, green:0.46, blue:0.30, alpha:1.0)
                        default:
                            repostCell.reportViewHeightConstraint.constant = 24
                        }
                    }
                } else {
                    repostCell.translatedTitleLabel.text = "Hier ist was schiefgelaufen!"
                }
                
                return repostCell
            }
        } else {    // Wenn nicht Repost, dann die andere
            let identifier = "NibPostCell"
            
            //Vielleicht noch absichern?!! Weiß aber nicht wie!
            tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: identifier)
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell {
                
                
                cell.delegate = self
                cell.setPost(post: post)

                cell.cellImageView.image = nil
                cell.profilePictureImageView.image = UIImage(named: "default-user")
                cell.titleLabel.text = nil
                
                cell.titleLabel.text = post.title
                cell.titleLabel.numberOfLines = 0
                cell.titleLabel.adjustsFontSizeToFitWidth = true
                cell.titleLabel.minimumScaleFactor = 0.5
                //cell.titleLabel.lineBreakMode = .byClipping
                
                cell.ogPosterLabel.text = post.originalPosterName
                
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.originalPosterImageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                cell.cellCreateDateLabel.text = post.createTime
                
                let postType = post.type
                
                if postType == "thought" {
                    cell.cellImageView.isHidden = true
                    cell.titleLabel.font = UIFont(name: "Kalam-Regular", size: 28.0)
                    cell.titleLabel.sizeToFit()
                    
                    
                } else if postType == "picture" {
                    cell.titleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    cell.titleLabel.sizeToFit()
                    
                    if let url = URL(string: post.imageURL) {
                        if let cellImageView = cell.cellImageView {
                            
                            cellImageView.isHidden = false      // Check ich nicht, aber geht!
                            
                            cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                            cellImageView.layer.cornerRadius = 5
                            cellImageView.clipsToBounds = true
                        }
                    }
                    
                } else if postType == "link" {
                    
                }
                if post.report == "normal" {
                    
                    cell.reportViewHeightConstraint.constant = 0
                    cell.reportViewButtonInTop.isHidden = true
                    
                } else {
                    
                    cell.reportViewHeightConstraint.constant = 24
                    cell.reportViewButtonInTop.isHidden = false
                    
                    
                    switch post.report {
                    case "opinion":
                        cell.reportViewLabel.text = "   Meinung, kein Fakt"
                        cell.reportView.backgroundColor = UIColor(red:0.27, green:0.00, blue:0.01, alpha:1.0)
                        
                    case "sensationalism":
                        cell.reportViewLabel.text = "   Sensationalismus"
                        cell.reportView.backgroundColor = UIColor(red:0.36, green:0.00, blue:0.01, alpha:1.0)
                    case "circlejerk":
                        cell.reportViewLabel.text = "   Circlejerk"
                        cell.reportView.backgroundColor = UIColor(red:0.58, green:0.04, blue:0.05, alpha:1.0)
                    case "pretentious":
                        cell.reportViewLabel.text = "   Angeberisch"
                        cell.reportView.backgroundColor = UIColor(red:0.83, green:0.05, blue:0.07, alpha:1.0)
                    case "edited":
                        cell.reportViewLabel.text = "   Nachbearbeitet"
                        cell.reportView.backgroundColor = UIColor(red:1.00, green:0.40, blue:0.36, alpha:1.0)
                    case "ignorant":
                        cell.reportViewLabel.text = "   Schwarz-Weiß-Denken"
                        cell.reportView.backgroundColor = UIColor(red:1.00, green:0.46, blue:0.30, alpha:1.0)
                    default:
                        cell.reportViewHeightConstraint.constant = 24
                        
                    }
                    
                }
                return cell
            }
        }
        return UITableViewCell()    // Falls das "if let" oben nicht zieht
    }
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        // Wenn es reported ist, ist es 24 höher!!!!!!?
        
        var heightForRow:CGFloat = 150
        
        let post = posts[indexPath.row]
        let postType = post.type
        
        let repostDocumentID = post.OGRepostDocumentID
        
        switch postType {
            /*case "thought":
             let letterCount = post.title.count
             
             if letterCount <= 100 {
             heightForRow = 125
             } else if letterCount <= 200 {
             heightForRow = 150
             } else {
             heightForRow = 200
             }*/
        case "picture":
            let imageHeight = post.imageHeight
            let imageWidth = post.imageWidth
            
            let ratio = imageWidth / imageHeight
            let newHeight = self.view.frame.width / ratio
            
            heightForRow = newHeight+100        // 100 weil das die Höhe von label und buttonStackView unten sein soll
            
            return heightForRow
            
            
        case "link":
            heightForRow = 500
        case "repost":
            if let repost = posts.first(where: {$0.documentID == repostDocumentID}) {
                let imageHeight = repost.imageHeight
                let imageWidth = repost.imageWidth
                
                let ratio = imageWidth / imageHeight
                let newHeight = self.view.frame.width / ratio
                
                heightForRow = newHeight+125        // 125 weil das die Höhe von dem ganzen Zeugs sein soll
                
                return heightForRow
            }
        default:
            heightForRow = 150
        }
        
        return heightForRow
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "meldenSegue" {
            if let chosenPost = sender as? Post {
                if let reportVC = segue.destination as? MeldenViewController {
                    reportVC.post = chosenPost
                    
                }
            }
        }
    }
}
