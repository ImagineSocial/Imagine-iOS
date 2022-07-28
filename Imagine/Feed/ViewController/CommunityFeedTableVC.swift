//
//  PostsOfFactTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.10.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import AVKit
import EasyTipView

enum TableViewDisplayOptions {
    case small
    case normal
}

class CommunityFeedTableVC: BaseFeedTableViewController {
    
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    var community: Community?
    
    var needNavigationController = false
    var displayOption: TableViewDisplayOptions = .normal
    
    let factParentVC = DiscussionParentVC()
    let radius:CGFloat = 6
    
    var tipView: EasyTipView?
    var followTopicTipView: EasyTipView?
    
    var isMainViewController = true
    
    weak var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    let defaults = UserDefaults.standard
    
    var postCount = 0
    var followerCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.noPostsType = .postsOfFacts
        self.isFactSegueEnabled = false //Cant go to this community from this community, right
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        let newHeight = Constants.Numbers.communityHeaderHeight
        tableView.contentInset = UIEdgeInsets(top: newHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -newHeight)
        
        setPlaceholders()
        getPosts()
    }
    
    override func getPosts() {
                
        guard let community = community, isConnected() else {
            fetchRequested = isConnected()
            return
        }
        
        view.activityStartAnimating()
        
        DispatchQueue.global(qos: .background).async {
            
            self.firestoreManager.getCommunityPosts(communityID: community.id) { posts in
                guard let posts = posts else {
                    print("No Posts")
                    DispatchQueue.main.async {
                        self.view.activityStopAnimating()
                    }
                    return
                }
                
                self.placeholderAreShown ? self.setPosts(posts) : self.appendPosts(posts)
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
    
    //MARK: - ScrollViewDidScroll
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        let offset = scrollView.contentOffset.y
        self.pageViewHeaderDelegate?.childScrollViewScrolled(offset: offset)
    }
    
    //MARK: - TableView
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        if let tipView = followTopicTipView {
            tipView.dismiss()
            followTopicTipView = nil
        } else {
            post.type == .nothingPostedYet ? tableView.deselectRow(at: indexPath, animated: true) : performSegue(withIdentifier: "showPost", sender: post)
        }
    }
    
    func changePostLocationForAddOnPosts(post: Post) {
        
        let topicID = "UOlUbkeFexR147dYh9eB"
        let addOnID = "2o6GSAPeYCYP3ZytD51l"
        
        let dataDictionary: [String: Any] = ["title": post.title, "description": post.description, "createTime": Timestamp(date: Date()), "originalPoster": post.user?.uid ?? "", "thanksCount":post.votes.thanks, "wowCount":post.votes.thanks, "haCount":post.votes.thanks, "niceCount":post.votes.thanks, "type": "thought", "report": "normal", "linkedFactID": topicID]
        /*
         "imageHeight": post.mediaHeight, "imageWidth": post.mediaWidth,
         */
        let topicPostRef = db.collection("Data").document("en").collection("topicPosts").document()
        
        topicPostRef.setData(dataDictionary) { (err) in
            if let error = err {
                print("error:", error.localizedDescription)
            }
        }
        
        let addOnData: [String: Any] = ["createdAt": Timestamp(date: Date()), "type": "topicPost", "OP": "CZOcL3VIwMemWwEfutKXGAfdlLy1"]
        let addOnRef = db.collection("Data").document("en").collection("topics").document(topicID).collection("addOns").document(addOnID).collection("items").document(topicPostRef.documentID)
        
        addOnRef.setData(addOnData) { (err) in
            if let error = err {
                print("error1:", error.localizedDescription)
            }
        }
        
        let topicRef = db.collection("Data").document("en").collection("topics").document(topicID).collection("posts").document(topicPostRef.documentID)
        
        let topicData: [String: Any] = ["createTime": Timestamp(date: Date()), "type": "topicPost"]
        topicRef.setData(topicData) { (err) in
            if let error = err {
                print("error2:", error.localizedDescription)
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
        if let community = community {
            performSegue(withIdentifier: "goToNewPost", sender: community)
        }
    }
    
    
    //MARK: - Prepare For Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "showPost":
            if let chosenPost = sender as? Post, let postVC = segue.destination as? PostViewController {
                postVC.post = chosenPost
                postVC.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
                postVC.navigationController?.navigationBar.shadowImage = nil
            }
        case "meldenSegue":
            if let chosenPost = sender as? Post, let reportVC = segue.destination as? ReportViewController {
                reportVC.post = chosenPost
            }
        case "toFactSegue":
            if let fact = sender as? Community, let navCon = segue.destination as? UINavigationController, let factVC = navCon.topViewController as? DiscussionParentVC {
                factVC.community = fact
                factVC.needNavigationController = true
            }
        case "goToNewPost" :
            if let fact = sender as? Community, let navCon = segue.destination as? UINavigationController, let newPostVC = navCon.topViewController as? NewPostVC {
                newPostVC.selectedFact(community: fact, isViewAlreadyLoaded: false)
                newPostVC.comingFromPostsOfFact = true
                newPostVC.isTopicPost = true
                newPostVC.newInstanceDelegate = self
            }
        case "toSettingSegue" :
            if let fact = sender as? Community, let vc = segue.destination as? SettingTableViewController {
                vc.topic = fact
                vc.settingFor = .community
            }
        case "toUserSegue" :
            if let userVC = segue.destination as? UserFeedTableViewController, let chosenUser = sender as? User {   // Another User
                userVC.user = chosenUser
                userVC.currentState = .otherUser
            }
        default:
            break
        }
    }
    
    override func userTapped(post: Post) {
        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
}

extension CommunityFeedTableVC: NewFactDelegate {
    
    func finishedCreatingNewInstance(item: Any?) {
        self.posts.removeAll()
        self.tableView.reloadData()
        self.getPosts()
    }
}
