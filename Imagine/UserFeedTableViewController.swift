//
//  UserFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 05.04.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SwiftLinkPreview

class UserFeedTableViewController: UITableViewController, PostCellDelegate {

    var posts = [Post]()
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
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
        
        if post.type == "repost" || post.type == "translation" {  // Wenn es ein Repost ist wird die RepostCell genommen
            let identifier = "NibRepostCell"
            
            //Vielleicht noch absichern?!! Weiß aber nicht wie!
            tableView.register(UINib(nibName: "RePostTableViewCell", bundle: nil), forCellReuseIdentifier: identifier)
            
            if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell {
                
                repostCell.cellImageView.image = nil
                repostCell.profilePictureImageView.image = UIImage(named: "default-user")
                repostCell.originalTitleLabel.text = nil
                repostCell.translatedTitleLabel.text = nil
                
                repostCell.OGPostView.layer.borderWidth = 1
                repostCell.OGPostView.layer.borderColor = UIColor.black.cgColor
                
                // Post Sachen einstellen
                repostCell.translatedTitleLabel.text = post.title
                repostCell.translatedTitleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                
                // Profile Picture
                let layer = repostCell.reposterProfilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = repostCell.reposterProfilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.originalPosterImageURL) {
                    repostCell.reposterProfilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                
                // Repost Sachen einstellen
                let repostDocumentID = post.OGRepostDocumentID
                if let repost = posts.first(where: {$0.documentID == repostDocumentID}) {
                    repostCell.originalTitleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    repostCell.originalTitleLabel.text = repost.title
                    repostCell.originalCreateDateLabel.text = repost.createTime
                    repostCell.ogPosterNameLabel.text = repost.originalPosterName
                    
                    // Profile Picture
                    let layer = repostCell.profilePictureImageView.layer
                    layer.masksToBounds = true
                    layer.cornerRadius = repostCell.profilePictureImageView.frame.width/2
                    layer.borderWidth = 0.1
                    layer.borderColor = UIColor.black.cgColor
                    
                    if let url = URL(string: repost.originalPosterImageURL) {
                        repostCell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                    }
                    
                    if let url = URL(string: repost.imageURL) {
                        if let repostCellImageView = repostCell.cellImageView {
                            
                            repostCellImageView.isHidden = false      // Check ich nicht, aber geht!
                            repostCellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                            repostCellImageView.layer.cornerRadius = 5
                            repostCellImageView.clipsToBounds = true
                        }
                    }
                    
                    // ReportView einstellen
                    let reportViewOptions = setReportView(post: post)
                    
                    repostCell.reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                    repostCell.reportViewButton.isHidden = reportViewOptions.buttonHidden
                    repostCell.reportViewLabel.text = reportViewOptions.labelText
                    repostCell.reportView.backgroundColor = reportViewOptions.backgroundColor
                    
                } else {
                    repostCell.translatedTitleLabel.text = "Hier ist was schiefgelaufen!"
                    print("Hier ist was schiefgelaufen: \(post.title)")
                }
                
                return repostCell
            }
            
        } else if post.type == "link" {
            let identifier = "NibLinkCell"
            
            //Vielleicht noch absichern?!! Weiß aber nicht wie!
            tableView.register(UINib(nibName: "LinkCell", bundle: nil), forCellReuseIdentifier: identifier)
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LinkCell {
                cell.linkThumbNailImageView.layer.cornerRadius = 3
                cell.linkThumbNailImageView.image = UIImage(named: "default")
                
                //Muss noch eingestellt werden cell.delegate = self // Um den link zu klicken
                cell.setPost(post: post)
                
                
                // Profile Picture
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.originalPosterImageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                cell.createDateLabel.text = post.createTime
                cell.ogPosterNameLabel.text = post.originalPosterName
                
                cell.titleLabel.lineBreakMode = .byWordWrapping
                cell.titleLabel.text = post.title
                cell.titleLabel.layoutIfNeeded()
                
                // Preview des Links anzeigen
                slp.preview(post.linkURL, onSuccess: { (result) in
                    if let imageURL = result.image {
                        cell.linkThumbNailImageView.sd_setImage(with: URL(string: imageURL), placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                    }
                    if let linkSource = result.canonicalUrl {
                        cell.urlLabel.text = linkSource
                    }
                }) { (error) in
                    print("We have an error: \(error.localizedDescription)")
                }
                
                
                // ReportView einstellen
                let reportViewOptions = setReportView(post: post)
                
                cell.reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                cell.reportViewButtonInTop.isHidden = reportViewOptions.buttonHidden
                cell.reportViewLabel.text = reportViewOptions.labelText
                cell.reportView.backgroundColor = reportViewOptions.backgroundColor
                
            }
            
        } else if post.type == "thought" {  // Gedanke
            
            let identifier = "NibThoughtCell"
            
            //Vielleicht noch absichern?!! Weiß aber nicht wie!
            tableView.register(UINib(nibName: "ThoughtPostCell", bundle: nil), forCellReuseIdentifier: identifier)
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                
                cell.titleLabel.text = nil
                cell.profilePictureImageView.image = UIImage(named: "default-user")
                
                cell.titleLabel.text = post.title
                cell.titleLabel.font = UIFont(name: "Kalam-Regular", size: 22.0)
                cell.titleLabel.sizeToFit()
                
                cell.createDateLabel.text = post.createTime
                cell.ogPosterLabel.text = post.originalPosterName
                
                // Profile Picture
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.originalPosterImageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                // ReportView einstellen
                let reportViewOptions = setReportView(post: post)
                
                cell.reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                cell.reportViewButtonInTop.isHidden = reportViewOptions.buttonHidden
                cell.reportViewLabel.text = reportViewOptions.labelText
                cell.reportView.backgroundColor = reportViewOptions.backgroundColor
                
                return cell
            }
        } else {    // Wenn nicht Repost oder Link, dann die andere
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
                cell.ogPosterLabel.text = post.originalPosterName
                cell.cellCreateDateLabel.text = post.createTime
                
                let letterCount = post.title.count
                
                if letterCount <= 40 {
                    cell.titleLabelHeightConstraint.constant = 40
                } else if letterCount <= 100 {
                    cell.titleLabelHeightConstraint.constant = 80
                } else if letterCount <= 150 {
                    cell.titleLabelHeightConstraint.constant = 100
                } else if letterCount <= 200 {
                    cell.titleLabelHeightConstraint.constant = 120
                } else if letterCount > 200 {
                    cell.titleLabelHeightConstraint.constant = 140
                }
                
                // Profile Picture
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.originalPosterImageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                
                if post.type == "thought" {
                    cell.cellImageView.isHidden = true
                    cell.titleLabel.font = UIFont(name: "Kalam-Regular", size: 28.0)
                    cell.titleLabel.sizeToFit()
                    
                } else if post.type == "picture" {
                    cell.titleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    cell.titleLabel.sizeToFit()
                    
                    if let url = URL(string: post.imageURL) {
                        if let cellImageView = cell.cellImageView {
                            
                            cellImageView.isHidden = false      // Check ich nicht, aber geht!
                            cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                            cellImageView.layer.cornerRadius = 1
                            cellImageView.clipsToBounds = true
                        }
                    }
                }
                
                // ReportView einstellen
                let reportViewOptions = setReportView(post: post)
                
                cell.reportViewHeightConstraint.constant = reportViewOptions.heightConstant
                cell.reportViewButtonInTop.isHidden = reportViewOptions.buttonHidden
                cell.reportViewLabel.text = reportViewOptions.labelText
                cell.reportView.backgroundColor = reportViewOptions.backgroundColor
                
                return cell
            }
        }
        return UITableViewCell()    // Falls das "if let" oben nicht zieht
    }
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    func setReportView(post: Post) -> (heightConstant:CGFloat, buttonHidden: Bool, labelText: String, backgroundColor: UIColor) {
        
        var reportViewHeightConstraint:CGFloat = 0
        var reportViewButtonInTopBoolean = false
        var reportViewLabelText = ""
        var reportViewBackgroundColor = UIColor.white
        
        if post.report == "normal" {
            reportViewHeightConstraint = 0
            reportViewButtonInTopBoolean = true
        } else {
            reportViewHeightConstraint = 24
            reportViewButtonInTopBoolean = false
            
            switch post.report {
                
            case "opinion":
                reportViewLabelText = "Meinung, kein Fakt"
                reportViewBackgroundColor = UIColor(red:0.27, green:0.00, blue:0.01, alpha:1.0)
            case "sensationalism":
                reportViewLabelText = "Sensationalismus"
                reportViewBackgroundColor = UIColor(red:0.36, green:0.00, blue:0.01, alpha:1.0)
            case "circlejerk":
                reportViewLabelText = "Circlejerk"
                reportViewBackgroundColor = UIColor(red:0.58, green:0.04, blue:0.05, alpha:1.0)
            case "pretentious":
                reportViewLabelText = "Angeberisch"
                reportViewBackgroundColor = UIColor(red:0.83, green:0.05, blue:0.07, alpha:1.0)
            case "edited":
                reportViewLabelText = "Nachbearbeitet"
                reportViewBackgroundColor = UIColor(red:1.00, green:0.40, blue:0.36, alpha:1.0)
            case "ignorant":
                reportViewLabelText = "Schwarz-Weiß-Denken"
                reportViewBackgroundColor = UIColor(red:1.00, green:0.46, blue:0.30, alpha:1.0)
            default:
                reportViewHeightConstraint = 24
            }
        }
        
        
        return (heightConstant: reportViewHeightConstraint, buttonHidden: reportViewButtonInTopBoolean, labelText: reportViewLabelText, backgroundColor: reportViewBackgroundColor)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var extraHeightForReportView:CGFloat = 0
        var titleLabelHeight:CGFloat = 30
        
        var heightForRow:CGFloat = 150
        
        let post = posts[indexPath.row]
        let postType = post.type
        
        if post.report != "normal" {
            extraHeightForReportView = 24
        }
        
        let repostDocumentID = post.OGRepostDocumentID
        
        switch postType {
        case "thought":
            return UITableView.automaticDimension
        case "picture":
            
            // Label vergrößern
            let letterCount = post.title.count
            if letterCount <= 40 {
                titleLabelHeight = 40
            } else if letterCount <= 100 {
                titleLabelHeight = 80
            } else if letterCount <= 150 {
                titleLabelHeight = 100
            } else if letterCount <= 200 {
                titleLabelHeight = 120
            } else if letterCount > 200 {
                titleLabelHeight = 140
            }
            
            let imageHeight = post.imageHeight
            let imageWidth = post.imageWidth
            
            let ratio = imageWidth / imageHeight
            let newHeight = self.view.frame.width / ratio
            
            heightForRow = newHeight+100+extraHeightForReportView+titleLabelHeight // 100 weil Höhe von StackView & Rest
            
            return heightForRow
        case "link":
            //return UITableView.automaticDimension klappt nicht
            heightForRow = 225
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
