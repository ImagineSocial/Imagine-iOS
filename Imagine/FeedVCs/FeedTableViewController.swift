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



class FeedTableViewController: UITableViewController, PostCellDelegate, LinkCellDelegate, RepostCellDelegate, ThoughtCellDelegate {
    
    var posts = [Post]()
    let slp = SwiftLinkPreview(session: URLSession.shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, cache: DisabledCache.instance)
    let imageCache = NSCache<NSString, UIImage>()
    
    var actInd: UIActivityIndicatorView = UIActivityIndicatorView()
    let container: UIView = UIView()
    
    lazy var postHelper = PostHelper()      // Lazy or it calls Firestore before AppDelegate.swift
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        imageCache.removeAllObjects()
        
        getPosts()
        showActivityIndicatory(uiView: self.view)
        
        tableViewSetup()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
    }
    
    
    func showActivityIndicatory(uiView: UIView) {
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.3)
        
        let loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:0.7)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        
        actInd.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0);
        actInd.style = .whiteLarge
        actInd.center = CGPoint(x: loadingView.frame.size.width / 2,
                                y: loadingView.frame.size.height / 2);
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        actInd.startAnimating()
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
        
        
            postHelper.getPosts { (posts) in
                
                print("Jetzt haben wir \(posts.count) posts")
                self.posts = posts
                self.tableView.reloadData()
                
                self.postHelper.getEvent(completion: { (post) in
                    self.posts.insert(post, at: posts.count-12)
                    self.tableView.reloadData()
                })
                
                // remove ActivityIndicator incl. backgroundView
                self.actInd.stopAnimating()
                self.container.isHidden = true
                
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
                if let repost = post.repost {
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
                    
                    // Das klappt nicht, weil der das in den 20 runtergeladenen Posts sucht und nicht in der Database in Firebase!!!!
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
        } else if post.type == "event" {     // Veranstaltun
            let identifier = "NibEventCell"
            
            //Vielleicht noch absichern?!! Weiß aber nicht wie!
            tableView.register(UINib(nibName: "EventCell", bundle: nil), forCellReuseIdentifier: identifier)
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? EventCell {
                
                cell.eventImageView.image = nil
                cell.headerLabel.text = nil
                
                cell.headerLabel.text = post.event.title
                
                cell.descriptionLabel.layer.cornerRadius = 5
                cell.descriptionLabel.clipsToBounds = true
                cell.descriptionLabel.text = post.event.description
                
                cell.locationLabel.text = post.event.location
                cell.timeLabel.text = "29.06.2019, 19:00 Uhr"
                cell.participantCountLabel.text = "15 Teilnehmer"
                
                switch post.event.type {
                case "project":
                    cell.typeLabel.text = "Ein interessantes Projekt für dich"
                case "event":
                    cell.typeLabel.text = "Ein interessantes Event für dich"
                case "activity":
                    cell.typeLabel.text = "Eine interessante Veranstaltung für dich"
                default:
                    cell.typeLabel.text = "Eine interessante Veranstaltung für dich"
                }
                
                
                
                if let url = URL(string: post.event.imageURL) {
                    if let cellImageView = cell.eventImageView {
                        
                        cellImageView.isHidden = false      // Check ich nicht, aber geht!
                        cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                        cellImageView.layer.cornerRadius = 1
                        cellImageView.clipsToBounds = true
                        
                    }
                }
                
                return cell
                
            }
            
        } else {// Wenn Picture
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
                    cell.profilePictureImageView.sd_setImage(with: url, completed: nil)
                }
                
                if let cachedImage = imageCache.object(forKey: post.imageURL as NSString) {
                    cell.cellImageView.image = cachedImage  // Using cached Image
                } else {
                        if let url = URL(string: post.imageURL) {   // Load and Cache Image
                        if let cellImageView = cell.cellImageView {
                            
                            cellImageView.isHidden = false      // Check ich nicht, aber geht!
                            cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: []) { (image, err, _, _) in
                                if let image = image {
                                    self.imageCache.setObject(image, forKey: post.imageURL as NSString)
                                }
                            }
                            cellImageView.layer.cornerRadius = 1
                            cellImageView.clipsToBounds = true
                            
                        }
                    }

                    
//                    if let url = URL(string: post.user.imageURL) {
//                        cell.profilePictureImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: []) { (image, err, _, _) in
//                            if let image = image {
//                                self.imageCache.setObject(image, forKey: post.user.imageURL as NSString)
//                            }
//                        }
//                    }
                }
                
//                if let url = URL(string: post.imageURL) {
//                    if let cellImageView = cell.cellImageView {
//
//                        cellImageView.isHidden = false      // Check ich nicht, aber geht!
//                        cellImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
//                        cellImageView.layer.cornerRadius = 1
//                        cellImageView.clipsToBounds = true
//
//                    }
//                }
                
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
    
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 &&
            indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 3 {
            print("Ende fast erreicht!")
            
            self.getPosts()
            // Wenn ich wirklich beim letzten bin habe ich noch keine Lösung
        }
    }
    
    
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    func thanksTapped(post: Post) {
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
        case "event": // veranstaltung
            
            return 469
        case "repost":
            if let repost = post.repost {
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

extension FeedTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let post = posts[indexPath.row]

            if let _ = imageCache.object(forKey: post.imageURL as NSString) {
                print("Wurde schon gecached")
            } else {
                if let url = URL(string: post.imageURL) {
                    print("Prefetchen neues Bild: \(post.title)")
                    DispatchQueue.global().async {
                        let data = try? Data(contentsOf: url)

                        DispatchQueue.main.async {
                            if let data = data {
                                if let image = UIImage(data: data) {
                                    self.imageCache.setObject(image, forKey: post.imageURL as NSString)
                            }
                        }
                    }
                }
            }
            }
        }
    }
    
}
