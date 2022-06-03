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
        
        getPosts(getMore: true)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        self.noPostsType = .savedPicture
        // navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func getPosts(getMore: Bool) {
        
        if isConnected() {
            
            if let user = AuthenticationManager.shared.user {
                firestoreRequest.getUserPosts(getMore: getMore, postList: .savedPosts, userUID: user.uid) { posts  in
                    
                    guard let posts = posts else {
                        print("No More Posts")
                        self.view.activityStopAnimating()
                        return
                    }
                                        
                    if placeholderAreShown {   // Get the first batch of posts
                        self.posts = posts
                        self.tableView.reloadData()
                        self.fetchesPosts = false
                        
                        self.refreshControl?.endRefreshing()
                        
                    } else {    // Append the next batch to the existing
                        var indexes = [IndexPath]()
                        
                        for result in posts {
                            let row = self.posts.count
                            indexes.append(IndexPath(row: row, section: 0))
                            self.posts.append(result)
                        }
                        
                        self.tableView.performBatchUpdates({
                            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                            self.tableView.insertRows(at: indexes, with: .bottom)
                        }, completion: { (_) in
                            self.fetchesPosts = false
                        })
                    }
                    print("Jetzt haben wir \(self.posts.count)")
                    
                    // remove ActivityIndicator incl. backgroundView
                    self.view.activityStopAnimating()
                }
            }
        } else {
            fetchRequested = true
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
        if segue.identifier == "showPost" {
            if let chosenPost = sender as? Post {
                if let postVC = segue.destination as? PostViewController {
                    postVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "toUserSegue" {
            if let chosenUser = sender as? User {
                if let userVC = segue.destination as? UserFeedTableViewController {
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                }
            }
        }
        
        if segue.identifier == "meldenSegue" {
            if let chosenPost = sender as? Post {
                if let reportVC = segue.destination as? ReportViewController {
                    reportVC.post = chosenPost
                }
            }
        }
        if segue.identifier == "toFactSegue" {
            if let community = sender as? Community {
               
                if let factVC = segue.destination as? CommunityPageVC {
                    
                    factVC.community = community
                }
                
            }
        }
    }
    
    override func userTapped(post: Post) {
        performSegue(withIdentifier: "toUserSegue", sender: post.user)
    }
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        // Takes care of toggling the button's title.
//        super.setEditing(!isEditing, animated: true)
//        
//        // Toggle table view editing.
//        tableView.setEditing(!tableView.isEditing, animated: true)
//    }

}
