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
    var firestoreRequest = FirestoreRequest()
    let db = FirestoreRequest.shared.db
    
    var sortOptionsShown = false
    var sortBy: PostSortOptions = .dateDecreasing
    
    let imageCache = NSCache<NSString, UIImage>()
    
    var fetchesPosts = true
    var noPostsType: BlankCellType = .savedPicture
    
    var fetchRequested = false
    
    let surveyCellIdentifier = "SurveyCell"
    let musicCellIdentifier = "MusicCell"
    let singleTopicCellIdentifier = "FeedSingleTopicCell"
    
    var isOwnProfile = false    //to change the button like count visibility
    
    var isFactSegueEnabled = true
    
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
        
        refreshControl.addTarget(self, action: #selector(getPosts(getMore:)), for: .valueChanged)   // getMore is false in this instance
        refreshControl.attributedTitle = NSAttributedString(string: NSLocalizedString("one_moment_placeholder", comment: "one moment..."))
        
        self.tableView.addSubview(refreshControl)
    }
    
    
    @objc func getPosts(getMore: Bool) {
        
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
                self.getPosts(getMore: true)
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

extension BaseFeedTableViewController: TopTopicCellDelegate {
    func owenTapped() {
        performSegue(withIdentifier: "toCreativeSpace", sender: nil)
    }
    
    func factOfTheWeekTapped(fact:Community) {
        performSegue(withIdentifier: "toFactSegue", sender: fact)
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
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        
        if distanceFromBottom < height {
            
            if fetchesPosts == false {
                print("Ende erreicht!")
                
                fetchesPosts = true
                self.getPosts(getMore: true)
            }
            
            // If I am at the total end of posts to fetch i got no solution for the feedtableview yet
        }
    }
}
