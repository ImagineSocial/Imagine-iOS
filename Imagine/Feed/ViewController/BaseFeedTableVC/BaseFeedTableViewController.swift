//
//  BaseFeedTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import SDWebImage
import AVKit

enum PostSortOptions {
    case dateDecreasing
    case dateIncreasing
    case thanksCount
    case wowCount
    case haCount
    case niceCount
}


class BaseFeedTableViewController: UITableViewController, ReachabilityObserverDelegate {
    
    var posts = [Post]()
    let handyHelper = HandyHelper.shared
    var firestoreManager = FirestoreManager()
    let db = FirestoreRequest.shared.db
    
    var morePostsAvailable = true
    
    var fetchInProgress = false
    var noPostsType: BlankCellType = .savedPicture
    
    var fetchRequested = false
        
    var isOwnProfile = false    //to change the button like count visibility
    
    var isFactSegueEnabled = true
    
    var placeholderAreShown: Bool {
        if let firstPost = posts.first, firstPost.documentID == nil {
            return true
        }
        
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.extendedLayoutIncludesOpaqueBars = true
        setupRefreshControl()
        setupTableView()
    }
    
    
    
    func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(reloadFeed), for: .valueChanged)   // getMore is false in this instance
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("one_moment_placeholder", comment: "one moment..."))
        
        self.tableView.addSubview(refreshControl)
    }
    
    
    @objc func getPosts() {
    }
    
    @objc func reloadFeed() {
        posts.removeAll()
        firestoreManager.reset()
        setPlaceholders()
        getPosts()
    }
    
    
    /// Show empty cells while fetching the posts
    func setPlaceholders() {
        var index = 0
        
        while index <= 4 {
            let post = Post.standard
            post.options = PostDesignOption(hideProfilePicture: true)
            if index == 1 {
                post.type = .picture
                post.image = PostImage(url: "", height: 150, width: 200)
            } else {
                post.type = .thought
            }
            self.posts.append(post)
            index += 1
        }
        
        self.tableView.reloadData()
    }
    
    func setPosts(_ posts: [Post]) {
        self.posts.removeAll()  //to get the placeholder out
        self.posts = posts
        fetchInProgress = false
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
                        
            // remove ActivityIndicator incl. backgroundView
            self.view.activityStopAnimating()

            self.refreshControl?.endRefreshing()
        }
    }
    
    func appendPosts(_ posts: [Post]) {
        
        guard !posts.isEmpty else { return }
        
        if let firstPost = posts.first, firstPost.type == .nothingPostedYet, !self.posts.isEmpty, !placeholderAreShown {
            // This means, we tried to fetch more posts, but got none. In this case the FirestoreManager returns a .nothingPostedYet Post which we catch here, if there is already more than one post, we dismiss this function. It just happens once, than the manager knows, that there are no post objects left.
            view.activityStopAnimating()
            return
        }
                
        let indexes = posts.enumerated().map { index, _ in
            IndexPath(row: self.posts.count + index, section: 0)
        }
        
        DispatchQueue.main.async {
            
            self.tableView.beginUpdates()
            self.posts.append(contentsOf: posts)
            self.tableView.insertRows(at: indexes, with: .bottom)
            self.tableView.endUpdates()
            
            self.fetchInProgress = false
            
            self.view.activityStopAnimating()
            print("Jetzt haben wir \(self.posts.count)")
        }
    }
    
    func returnedPostsAreEmpty() {
        if placeholderAreShown {
            // Hide loading placeholder and show empty placeholder
        } else {
            morePostsAvailable = false
        }
    }
    
    //InfoView
    
    func presentInfoView() {
        
    }
    
    //MARK: - GetName
    
    var index = 0
    func getName(row: Int) {
        if index < 20, posts.count != 0 {
            if self.posts[row].user == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.getName(row: row)
                    self.index+=1
                }
            } else {
                self.tableView.reloadData()
            }
        }
    }
    
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        let cgSize = CGSize(width: abs(size.width), height: abs(size.height))

        return cgSize
    }
    
    
    //MARK: - Others
    
    func reachabilityChanged(_ isReachable: Bool) {
        print("changed! Connection reachable: ", isReachable, "fetch requested: ", fetchRequested)
        
        if isReachable {
            if fetchRequested { // To automatically redo the requested task
                self.getPosts()
            }
        } else {
            // Just in the FeedTableVC
        }
    }
    
    
    // Not in the extension because i could not override it and dont want performSegue in Usertableview
    func userTapped(post: Post) {
    }
}

//MARK: - SurveyCell

extension BaseFeedTableViewController: SurveyCellDelegate {
    
    func surveyCompleted(surveyID: String, indexPath: IndexPath, data: [Any], comment: String?) {
        saveSurveyDataInDatabase(surveyID: surveyID, data: data, comment: comment)
        removeSurveyCell(at: indexPath)
    }
    
    func dontShowAgain(surveyID: String, indexPath: IndexPath) {
        hideSurveyFromUser(surveyID: surveyID)
        removeSurveyCell(at: indexPath)
    }
    
    func removeSurveyCell(at indexPath: IndexPath) {
        tableView.beginUpdates()
        self.posts.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
    }
    
    func saveSurveyDataInDatabase(surveyID: String, data: [Any], comment: String?) {
        let ref = db.collection("Feedback").document("surveys").collection("surveys").document(surveyID)
        
        let stringData = data.map({"\($0)"}).joined(separator: ",")
        
        if let comment = comment {
            ref.updateData([
                "comments" : FieldValue.arrayUnion([comment])
            ]) { (err) in
                if let error = err {
                    print("We have an error with the comment: \(error.localizedDescription)")
                } else {
                    self.hideSurveyFromUser(surveyID: surveyID)
                }
            }
        }
        
        ref.updateData([
            stringData : FieldValue.increment(Int64(1))
        ]) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
                self.createSurveyDocument(surveyID: surveyID, comment: comment, data: [stringData:1])
            } else {
                print("SUccessfully added Feedback")
                self.hideSurveyFromUser(surveyID: surveyID)
            }
        }
    }
    
    func createSurveyDocument(surveyID: String, comment: String?, data: [String:Any]) {
        let ref = db.collection("Feedback").document("surveys").collection("surveys").document(surveyID)
        
        var data = data
        if let comment = comment {
            data["comments"] = comment
        }
        
        ref.setData(data) { (err) in
            if let error = err {
                print("We really have an error!: \(error.localizedDescription)")
            } else {
                self.hideSurveyFromUser(surveyID: surveyID)
            }
        }
    }
    
    func hideSurveyFromUser(surveyID: String) {
        let defaults = UserDefaults.standard
        let hiddenSurveyArrayString = Constants.userDefaultsStrings.hideSurveyString
        var surveyStrings = defaults.stringArray(forKey: hiddenSurveyArrayString) ?? [String]()
        
        surveyStrings.append(surveyID)
        defaults.set(surveyStrings, forKey: hiddenSurveyArrayString)
    }
}

extension BaseFeedTableViewController: PostCellDelegate {
    
    func collectionViewTapped(post: Post) {
        performSegue(withIdentifier: "showPost", sender: post)
    }
    
    // MARK: Cell Button Tapped
    
    func reportTapped(post: Post) {
        performSegue(withIdentifier: "meldenSegue", sender: post)
    }
    
    func thanksTapped(post: Post) {
        if AuthenticationManager.shared.isLoggedIn {
            handyHelper.updatePost(button: .thanks, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func wowTapped(post: Post) {
        if AuthenticationManager.shared.isLoggedIn {
        handyHelper.updatePost(button: .wow, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func haTapped(post: Post) {
        if AuthenticationManager.shared.isLoggedIn {
        handyHelper.updatePost(button: .ha, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func niceTapped(post: Post) {
        if AuthenticationManager.shared.isLoggedIn {
            handyHelper.updatePost(button: .nice, post: post)
        } else {
            self.notLoggedInAlert()
        }
    }
    
    func linkTapped(post: Post) {
        let vc = WebVC()
        vc.post = post
        
        let navVC = UINavigationController(rootViewController: vc)
        navVC.isToolbarHidden = false
        
        present(navVC, animated: true)
    }
    
    func factTapped(fact: Community) {
        if isFactSegueEnabled {
            performSegue(withIdentifier: "toFactSegue", sender: fact)
        }
    }
    
    
    
}

extension BaseFeedTableViewController: MusicPostDelegate {
    func expandView() {
        tableView.beginUpdates()
        tableView.endUpdates()
        print("TableViewUpdate")
    }
}

extension BaseFeedTableViewController {
    
    // MARK: - ScrollViewDelegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard viewIfLoaded?.window != nil else {
            print("Not there yet")
            return
        }
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        if distanceFromBottom < height, !fetchInProgress && morePostsAvailable {
            print("End reached!")
            getPosts()
        }
    }
}
