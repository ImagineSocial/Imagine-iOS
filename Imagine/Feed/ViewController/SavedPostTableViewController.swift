//
//  SavedPostTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class SavedPostTableViewController: BaseFeedTableViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setPlaceholders()
        getPosts()
        navigationController?.hideHairline()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.noPostsType = .savedPicture
    }
    
    override func getPosts() {
        guard isConnected(), !fetchInProgress, let userID = AuthenticationManager.shared.user?.uid else {
            fetchRequested = !isConnected()
            return
        }
        
        self.view.activityStartAnimating()
        self.fetchInProgress = true
        
        DispatchQueue.global(qos: .background).async {
            self.firestoreManager.getSavedPosts(userID: userID) { posts in
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
        switch post.type {
        case .nothingPostedYet:
            print("Nothing will happen")
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            performSegue(withIdentifier: "showPost", sender: post)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost", let chosenPost = sender as? Post, let postVC = segue.destination as? PostViewController {
            postVC.post = chosenPost
        }
        
        if segue.identifier == "toUserSegue", let chosenUser = sender as? User, let userVC = segue.destination as? UserFeedTableViewController {
            userVC.user = chosenUser
            userVC.currentState = .otherUser
        }
        
        if segue.identifier == "meldenSegue", let chosenPost = sender as? Post, let reportVC = segue.destination as? ReportViewController {
            reportVC.post = chosenPost
        }
        if segue.identifier == "toFactSegue", let community = sender as? Community, let communityVC = segue.destination as? CommunityPageVC {
            communityVC.community = community
        }
    }
    
    override func userTapped(post: Post) {
        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
}
