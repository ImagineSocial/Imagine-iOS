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

class PostsOfFactTableViewController: BaseFeedTableViewController {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var fact: Fact?
    
    var needNavigationController = false
    var displayOption: TableViewDisplayOptions = .normal
    
    let factParentVC = FactParentContainerViewController()
    let radius:CGFloat = 6
    
    var tipView: EasyTipView?
    var followTopicTipView: EasyTipView?
    
    var isMainViewController = true
    
    var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    let defaults = UserDefaults.standard
    
    var postCount = 0
    var followerCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isFactSegueEnabled = false //Cant go to this community from this community, right
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let newHeight = Constants.Numbers.communityHeaderHeight
        tableView.contentInset = UIEdgeInsets(top: newHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -newHeight)
        
        setPlaceholderAndGetPosts()
    }
    
    func setPlaceholderAndGetPosts() {
        //setPlaceholder
        var index = 0
        
        while index <= 2 {
            let post = Post()
            if index == 1 {
                post.type = .picture
            } else {
                post.type = .thought
            }
            self.posts.append(post)
            index+=1
        }
        
        self.tableView.reloadData()
        getPosts(getMore: true)
    }
    
    override func getPosts(getMore: Bool) {
        if let fact = fact {
            if isConnected() {
                
                self.view.activityStartAnimating()
                
                DispatchQueue.global(qos: .default).async {
                    self.postHelper.getPostsForCommunity(getMore: getMore, communityID: fact.documentID) { (posts, initialFetch) in
                        if let posts = posts {
                            if initialFetch {   // Get the first batch of posts
                                
                                self.posts.removeAll()  //to get the placeholder out
                                self.posts = posts
                                
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                    
                                    self.fetchesPosts = false
                                    
                                    // remove ActivityIndicator incl. backgroundView
                                    self.view.activityStopAnimating()
                                    
                                    self.refreshControl?.endRefreshing()
                                    self.explainFunctions()
                                }
                            } else {    // Append the next batch to the existing
                                var indexes : [IndexPath] = [IndexPath]()
                                
                                for result in posts {
                                    let row = self.posts.count
                                    
                                    indexes.append(IndexPath(row: row, section: 0))
                                    self.posts.append(result)
                                }
                                
                                DispatchQueue.main.async {
                                    
                                    if #available(iOS 11.0, *) {
                                        self.tableView.performBatchUpdates({
                                            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                                            self.tableView.insertRows(at: indexes, with: .bottom)
                                        }, completion: { (_) in
                                            self.fetchesPosts = false
                                        })
                                    } else {
                                        self.tableView.beginUpdates()
                                        self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                                        self.tableView.insertRows(at: indexes, with: .right)
                                        self.tableView.endUpdates()
                                        
                                        self.fetchesPosts = false
                                    }
                                    
                                    self.view.activityStopAnimating()
                                }
                            }
                        } else {
                            self.view.activityStopAnimating()
                        }
                    }
                }
            } else {
                fetchRequested = true
            }
        }
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
    
    //MARK:- ScrollViewDidScroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        self.pageViewHeaderDelegate?.childScrollViewScrolled(offset: offset)
        
        let height = scrollView.frame.size.height
        let distanceFromBottom = scrollView.contentSize.height - offset
        
        if distanceFromBottom < height {
            if fetchesPosts == false {
                print("##Ende erreicht!")
                
                fetchesPosts = true
                self.getPosts(getMore: true)
            }
        }
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
        
        if segue.identifier == "goToLink" {
            if let post = sender as? Post {
                if let webVC = segue.destination as? WebViewController {
                    webVC.post = post
                }
            }
        }
    }
    
    override func userTapped(post: Post) {
        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
    
    @IBAction func toSettingsTapped(_ sender: Any) {
        if let fact = fact {
            performSegue(withIdentifier: "toSettingSegue", sender: fact)
        }
    }
}

extension PostsOfFactTableViewController: NewFactDelegate {
    
    func finishedCreatingNewInstance(item: Any?) {
        self.posts.removeAll()
        self.tableView.reloadData()
        self.getPosts(getMore: false)
    }
    
}

