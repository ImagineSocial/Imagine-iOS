//
//  FeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 25.02.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import SDWebImage
import SwiftLinkPreview

/*
 let lastCell = photos.count - 1
 if indexPath.row == lastCell {
 self.loadMore()
 Wenn ich das Schrittweise Laden möchte
 
 Cachen muss ich das auch noch
 */



class FeedTableViewController: UITableViewController, PostCellDelegate, LinkCellDelegate, RepostCellDelegate, ThoughtCellDelegate {
    
    var posts = [Post]()
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        getPosts()
        
        tableViewSetup()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
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
        PostHelper().getPosts { (posts) in
            self.posts = posts
            
            for post in posts {
            }
            self.tableView.reloadData()
            
            self.refreshControl?.endRefreshing()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
                
                repostCell.delegate = self
                repostCell.setPost(post: post)
                
                repostCell.cellImageView.image = nil
                repostCell.profilePictureImageView.image = UIImage(named: "default-user")
                repostCell.originalTitleLabel.text = nil
                repostCell.translatedTitleLabel.text = nil
                
                repostCell.OGPostView.layer.borderWidth = 1
                repostCell.OGPostView.layer.borderColor = UIColor.black.cgColor
                
                // Post Sachen einstellen
                repostCell.translatedTitleLabel.text = post.title
                repostCell.reposterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                repostCell.repostDateLabel.text = post.createTime
                
                repostCell.thanksCountLabel.text = "thanks"
                repostCell.wowCountLabel.text = "wow"
                repostCell.haCountLabel.text = "ha"
                repostCell.niceCountLabel.text = "nice"
                repostCell.commentCountLabel.text = String(post.commentCount)
                
                // Profile Picture
                let layer = repostCell.reposterProfilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = repostCell.reposterProfilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.user.imageURL) {
                    repostCell.reposterProfilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                
                // Repost Sachen einstellen
                let repostDocumentID = post.OGRepostDocumentID
                if let repost = posts.first(where: {$0.documentID == repostDocumentID}) {
                    repostCell.originalTitleLabel.font = UIFont(name: "Kalam-Regular", size: 20.0)
                    repostCell.originalTitleLabel.text = repost.title
                    repostCell.originalCreateDateLabel.text = repost.createTime
                    repostCell.ogPosterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                    
                    // Profile Picture
                    let layer = repostCell.profilePictureImageView.layer
                    layer.masksToBounds = true
                    layer.cornerRadius = repostCell.profilePictureImageView.frame.width/2
                    layer.borderWidth = 0.1
                    layer.borderColor = UIColor.black.cgColor
                    
                    if let url = URL(string: repost.user.imageURL) {
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
                cell.linkThumbNailImageView.image = UIImage(named: "default")
                cell.linkThumbNailImageView.layer.cornerRadius = 3
                
                cell.delegate = self // Um den link zu klicken
                cell.setPost(post: post)
                
                cell.thanksCountLabel.text = "thanks"
                cell.wowCountLabel.text = "wow"
                cell.haCountLabel.text = "ha"
                cell.niceCountLabel.text = "nice"
                cell.commentCountLabel.text = String(post.commentCount)
                
                // Profile Picture
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.user.imageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                cell.createDateLabel.text = post.createTime
                cell.ogPosterNameLabel.text = "\(post.user.name) \(post.user.surname)"
                
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
                
                
                return cell
            }
        } else if post.type == "thought" {  // Gedanke
            
            let identifier = "NibThoughtCell"
            
            //Vielleicht noch absichern?!! Weiß aber nicht wie!
            tableView.register(UINib(nibName: "ThoughtPostCell", bundle: nil), forCellReuseIdentifier: identifier)
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                
                cell.delegate = self
                cell.setPost(post: post)
                
                cell.titleLabel.text = nil
                cell.profilePictureImageView.image = UIImage(named: "default-user")
                
                cell.titleLabel.text = post.title
                cell.titleLabel.font = UIFont(name: "Kalam-Regular", size: 22.0)
                cell.titleLabel.sizeToFit()
                
                cell.thanksCountLabel.text = "thanks"
                cell.wowCountLabel.text = "wow"
                cell.haCountLabel.text = "ha"
                cell.niceCountLabel.text = "nice"
                cell.commentCountLabel.text = String(post.commentCount)
                
                cell.createDateLabel.text = post.createTime
                cell.ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
                
                // Profile Picture
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                if let url = URL(string: post.user.imageURL) {
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
        } else { // Wenn Picture
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
                
                cell.thanksCountLabel.text = "thanks"
                cell.wowCountLabel.text = "wow"
                cell.haCountLabel.text = "ha"
                cell.niceCountLabel.text = "nice"
                cell.commentCountLabel.text = String(post.commentCount)
                
                cell.ogPosterLabel.text = "\(post.user.name) \(post.user.surname)"
                cell.cellCreateDateLabel.text = post.createTime
                
                let labelHeight = setLabelHeight(titleCount: post.title.count)
                cell.titleLabelHeightConstraint.constant = labelHeight
                
                // Profile Picture
                let layer = cell.profilePictureImageView.layer
                layer.masksToBounds = true
                layer.cornerRadius = cell.profilePictureImageView.frame.width/2
                layer.borderWidth = 0.1
                layer.borderColor = UIColor.black.cgColor
                
                
                if let url = URL(string: post.user.imageURL) {
                    cell.profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                }
                
                
                if let url = URL(string: post.imageURL) {
                    if let cellImageView = cell.cellImageView {
                        
                        cellImageView.isHidden = false      // Check ich nicht, aber geht!
                        cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                        cellImageView.layer.cornerRadius = 1
                        cellImageView.clipsToBounds = true
                        
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
    
    func thanksTapped(post: Post) {
        print("Post wird geupdatet!")
        updatePost(button: "thanks", post: post)
    }
    
    func wowTapped(post: Post) {
        updatePost(button: "wow", post: post)
    }
    
    func haTapped(post: Post) {
        updatePost(button: "ha", post: post)
    }
    
    func niceTapped(post: Post) {
        updatePost(button: "nice", post: post)
    }
    
    
    func updatePost(button: String, post: Post) {
        let db = Firestore.firestore().collection("Posts").document(post.documentID)
        var keyForFirestore = ""
        var valueForFirestore = 0
        
        switch button {
        case "thanks":
            valueForFirestore = post.votes.thanks+1
            keyForFirestore = "thanksCount"
        case "wow":
            valueForFirestore = post.votes.wow+1
            keyForFirestore = "wowCount"
        case "ha":
            valueForFirestore = post.votes.ha+1
            keyForFirestore = "haCount"
        case "nice":
            valueForFirestore = post.votes.nice+1
            keyForFirestore = "niceCount"
        default:
            valueForFirestore = 0
            keyForFirestore = ""
        }
        
        if keyForFirestore != "" {
            //db.setValue(valueForFirestore, forKey: keyForFirestore)
            db.updateData([keyForFirestore:valueForFirestore])
        } else {
            print("konnte nicht geupdatet werden")
        }
    }
    
    
    func linkTapped(post: Post) {
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    func setLabelHeight(titleCount: Int) -> CGFloat {
        // Stellt die Höhe für das TitleLabel ein bei cellForRow und HeightForRow
        var labelHeight : CGFloat = 10
        
        if titleCount <= 40 {
            labelHeight = 40
        } else if titleCount <= 100 {
            labelHeight = 80
        } else if titleCount <= 150 {
            labelHeight = 100
        } else if titleCount <= 200 {
            labelHeight = 120
        } else if titleCount > 200 {
            labelHeight = 140
        }
        
        return labelHeight
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
            let labelHeight = setLabelHeight(titleCount: post.title.count)
            
            let imageHeight = post.imageHeight
            let imageWidth = post.imageWidth
            
            let ratio = imageWidth / imageHeight
            let newHeight = self.view.frame.width / ratio
            
            heightForRow = newHeight+100+extraHeightForReportView+labelHeight // 100 weil Höhe von StackView & Rest
            
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
        if segue.identifier == "goToLink" {
            if let chosenPost = sender as? Post {
                if let webVC = segue.destination as? WebViewController {
                    webVC.post = chosenPost
                    
                }
            }
        }
    }
    
}
