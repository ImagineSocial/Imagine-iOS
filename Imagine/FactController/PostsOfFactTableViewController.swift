//
//  PostsOfFactTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.10.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import AVKit
import EasyTipView

enum TableViewDisplayOptions {
    case small
    case normal
}

class PostsOfFactTableViewController: UITableViewController {

    @IBOutlet weak var infoButton: UIBarButtonItem!

    
    var fact: Fact?
    var noPostsType: BlankCellType = .postsOfFacts
    var posts = [Post]()
    var needNavigationController = false
    var displayOption: TableViewDisplayOptions = .normal
    
    let postHelper = PostHelper()
    let handyHelper = HandyHelper()
    let factParentVC = FactParentContainerViewController()
    let radius:CGFloat = 6
    
    var tipView: EasyTipView?
    var followTopicTipView: EasyTipView?
    
    var isMainViewController = true
    
    var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    let defaults = UserDefaults.standard
    let smallDisplayTypeUserDefaultsPhrase = "smallDisplayType"
    let musicCellIdentifier = "MusicCell"
    
    var postCount = 0
    var followerCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.navigationController?.navigationBar.shadowImage = UIImage()
        tableView.separatorStyle = .none
        if #available(iOS 13.0, *) {
            tableView.backgroundColor = .systemBackground
        } else {
            tableView.backgroundColor = .white
        }
        
        //for small display option
        tableView.register(UINib(nibName: "BlankContentCell", bundle: nil), forCellReuseIdentifier: "NibBlankCell")
        tableView.register(SearchPostCell.self, forCellReuseIdentifier: "SearchPostCell")
        
        // For normal display
        tableView.register(UINib(nibName: "RePostTableViewCell", bundle: nil), forCellReuseIdentifier: "NibRepostCell")
        tableView.register(UINib(nibName: "PostTableViewCell", bundle: nil), forCellReuseIdentifier: "NibPostCell")
        tableView.register(UINib(nibName: "LinkCell", bundle: nil), forCellReuseIdentifier: "NibLinkCell")
        tableView.register(UINib(nibName: "ThoughtPostCell", bundle: nil), forCellReuseIdentifier: "NibThoughtCell")
        tableView.register(UINib(nibName: "YouTubeCell", bundle: nil), forCellReuseIdentifier: "NibYouTubeCell")
        tableView.register(UINib(nibName: "GifCell", bundle: nil), forCellReuseIdentifier: "GIFCell")
        tableView.register(UINib(nibName: "MultiPictureCell", bundle: nil), forCellReuseIdentifier: "MultiPictureCell")
        tableView.register(UINib(nibName: "MusicCell", bundle: nil), forCellReuseIdentifier: musicCellIdentifier)

        getPosts()
        
        
        // The type of presentation can vary between the normal and small cells. Saved in UserDefault
        let type = defaults.bool(forKey: smallDisplayTypeUserDefaultsPhrase)
        
        if type {
            self.displayOption = .small
        }
        
        let newHeight = Constants.Numbers.communityHeaderHeight
        tableView.contentInset = UIEdgeInsets(top: newHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -newHeight)
        
    }
    
    func hintTheOtherView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            
            UIView.animate(withDuration: 0.4, animations: {
                self.view.frame.origin.x += 50
            }) { (_) in
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    self.view.frame.origin.x -= 50
                }) { (_) in
                    // Do something when it is finished
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
        if let tipView = followTopicTipView  {
            tipView.dismiss()
            followTopicTipView = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
            self.tipView = nil
        }
        if let tipView = followTopicTipView  {
            tipView.dismiss()
            followTopicTipView = nil
        }
    }

    func getPosts() {
        
        if let fact = fact {
            self.view.activityStartAnimating()
            
            postHelper.getPostsForFact(factID: fact.documentID, forPreviewPictures: false) { (posts) in
                self.posts = posts
                self.tableView.reloadData()
                self.view.activityStopAnimating()
                
                self.explainFunctions()
            }
        }
    }
    
    func explainFunctions() {
        
        if isMainViewController {
            if let _ = defaults.string(forKey: "showFollowFunction") {
                
                let count = defaults.integer(forKey: "TimesOpenedCommunity")
                print("THat is how many Times: \(count)")
                
                if count < 6 {
                    hintTheOtherView()
                    defaults.set(count+1, forKey: "TimesOpenedCommunity")
                }
                
            } else {
                showFollowTopicExplanation()
                defaults.set(true, forKey: "showFollowFunction")
                print("Community launched first time")
            }
        }
    }
    
    func showFollowTopicExplanation() {
        followTopicTipView = EasyTipView(text: NSLocalizedString("follow_community_description", comment: "Why should you follow a topic?"))
    }
    
    //MARK:-ScrollViewDidScroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        self.pageViewHeaderDelegate?.childScrollViewScrolled(offset: offset)
    }
    
    //MARK:- TableView
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        if let tipView = followTopicTipView  {
            tipView.dismiss()
            followTopicTipView = nil
        } else {
            switch post.type {
            case .nothingPostedYet:
                print("Nothing will happen")
                tableView.deselectRow(at: indexPath, animated: true)
            default:
                performSegue(withIdentifier: "showPost", sender: post)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "NibBlankCell", for: indexPath) as? BlankContentCell {
                
                cell.type = noPostsType
                cell.contentView.backgroundColor = self.tableView.backgroundColor
                
                return cell
            }
        default:
            
            switch displayOption {
            case .normal:
                
                switch post.type {
                case .repost:
                    let identifier = "NibRepostCell"
                    
                    if let repostCell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? RePostCell {
                        
                        repostCell.delegate = self
                        repostCell.post = post
                        
                        return repostCell
                    }
                case .picture:
                    let identifier = "NibPostCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? PostCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                case .thought:
                    let identifier = "NibThoughtCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                case .link:
                    if post.linkURL.contains("songwhip.com") {
                        
                        if let cell = tableView.dequeueReusableCell(withIdentifier: musicCellIdentifier, for: indexPath) as? MusicCell {
                            cell.post = post
                            cell.delegate = self
                            cell.webViewDelegate = self
                            
                            return cell
                        }
                    } else {
                        let identifier = "NibLinkCell"
                        
                        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? LinkCell {
                            
                            cell.delegate = self
                            cell.post = post
                            
                            return cell
                        }
                    }
                case .youTubeVideo:
                    let identifier = "NibYouTubeCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? YouTubeCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                case .GIF:
                    let identifier = "GIFCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? GifCell {
                     
                        cell.post = post
                        cell.delegate = self
                        if let url = URL(string: post.linkURL) {
                            cell.videoPlayerItem = AVPlayerItem.init(url: url)
                            cell.startPlayback()
                        }
                        
                        return cell
                    }
                case .multiPicture:
                    let identifier = "MultiPictureCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MultiPictureCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                default:
                    let identifier = "NibThoughtCell"
                    
                    if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ThoughtCell {
                        
                        cell.delegate = self
                        cell.post = post
                        
                        return cell
                    }
                }
                
            case .small:
                if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPostCell", for: indexPath) as? SearchPostCell {
                    
                    cell.post = post
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            return self.view.frame.height-150
        default:
            
            switch displayOption {
            case .normal:
                var extraHeightForReportView:CGFloat = 0
                
                var heightForRow:CGFloat = 150
                
                let post = posts[indexPath.row]
                let postType = post.type
                
                switch post.report {
                case .normal:
                    extraHeightForReportView = 0
                default:
                    extraHeightForReportView = 24
                }
                
                switch postType {
                case .thought:
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return 110+labelHeight+extraHeightForReportView
                case .picture:
                    
                    // Label vergrößern
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    let imageHeight = post.mediaHeight
                    let imageWidth = post.mediaWidth
                    
                    let ratio = imageWidth / imageHeight
                    let width = self.view.frame.width-20
                    var newHeight = width / ratio
                    
                    if newHeight >= 500 {
                        newHeight = 500
                    }
                    
                    heightForRow = newHeight+105+extraHeightForReportView+labelHeight // 100 weil Höhe von StackView & Rest
                    
                    return heightForRow
                case .link:
                    
                    if post.linkURL.contains("songwhip.com") {
                        return UITableView.automaticDimension
                    } else {
                        let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                        let height = 300+extraHeightForReportView+labelHeight
                        
                        return height
                    }
                case .repost:
                    
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return 390+extraHeightForReportView+labelHeight //525
                    
                case .youTubeVideo:
                    
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return 330+labelHeight
                case .GIF:
                    
                    let imageHeight = post.mediaHeight
                    let imageWidth = post.mediaWidth
                    
                    let ratio = imageWidth / imageHeight
                    var newHeight = self.view.frame.width / ratio
                    
                    if newHeight >= 500 {
                        newHeight = 500
                    }
                    
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    return newHeight+85+labelHeight //85 is height of title, profileicture, buttons etc.
                //                return UITableView.automaticDimension
                case .multiPicture:
                    // Label vergrößern
                    let labelHeight = handyHelper.setLabelHeight(titleCount: post.title.count)
                    
                    let imageHeight = post.mediaHeight
                    let imageWidth = post.mediaWidth
                    
                    let ratio = imageWidth / imageHeight
                    let width = self.view.frame.width-20
                    var newHeight = width / ratio
                    
                    if newHeight >= 500 {
                        newHeight = 500
                    }
                    
                    
                    heightForRow = newHeight+100+extraHeightForReportView+labelHeight // 100 weil Höhe von StackView & Rest
                    
                    return heightForRow
                default:
                    return 300
                }
                
                return heightForRow
            case .small:
                return 80
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.postOfFactText)
            tipView!.show(forItem: infoButton)
        }
    }
    
    @IBAction func newPostTapped(_ sender: Any) {
        if let fact = fact {
            performSegue(withIdentifier: "goToNewPost", sender: fact)
        }
    }
    
    
    //MARK:- Prepare For Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                    postVC.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                    postVC.navigationController?.navigationBar.shadowImage = nil
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
        
        if segue.identifier == "toFactSegue" {
            if let fact = sender as? Fact {
                if let navCon = segue.destination as? UINavigationController {
                    if let factVC = navCon.topViewController as? FactParentContainerViewController {
                        factVC.fact = fact
                        factVC.needNavigationController = true
                    }
                }
            }
        }
        
        if segue.identifier == "goToNewPost" {
            if let fact = sender as? Fact {
                if let navCon = segue.destination as? UINavigationController {
                    if let newPostVC = navCon.topViewController as? NewPostViewController {
                        newPostVC.selectedFact(fact: fact, isViewAlreadyLoaded: false)
                        newPostVC.comingFromPostsOfFact = true
                        newPostVC.postOnlyInTopic = true
                        newPostVC.newInstanceDelegate = self
                    }
                }
            }
        }
        
        if segue.identifier == "toSettingSegue" {
            if let fact = sender as? Fact {
                if let vc = segue.destination as? SettingTableViewController {
                    vc.topic = fact
                    vc.settingFor = .community
                }
            }
        }
        
        if segue.identifier == "toUserSegue" {
            if let userVC = segue.destination as? UserFeedTableViewController {
                if let chosenUser = sender as? User {   // Another User
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                } 
            }
        }
    }
    
    @IBAction func toSettingsTapped(_ sender: Any) {
        if let fact = fact {
            performSegue(withIdentifier: "toSettingSegue", sender: fact)
        }
    }
    //MARK:- PostCell Delegate
    
}

extension PostsOfFactTableViewController: PostCellDelegate, NewFactDelegate, MusicPostDelegate {
    
    func expandView() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    
    func finishedCreatingNewInstance(item: Any?) {
        self.posts.removeAll()
        self.tableView.reloadData()
        self.getPosts()
    }
    
    func collectionViewTapped(post: Post) {
        performSegue(withIdentifier: "showPost", sender: post)
    }
    
    
    func userTapped(post: Post) {
        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
    
    // MARK: Cell Button Tapped
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    func thanksTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .thanks, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func wowTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .wow, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func haTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .ha, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func niceTapped(post: Post) {
        if let _ = Auth.auth().currentUser {
            handyHelper.updatePost(button: .nice, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func linkTapped(post: Post) {
        performSegue(withIdentifier: "goToLink", sender: post)
    }
    
    func factTapped(fact: Fact) {
        //nothing has to happen
    }
    
}

