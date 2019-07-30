//
//  SavedPostTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class SavedPostTableViewController: BaseFeedTableViewController {
    
    lazy var postHelper = PostHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getPosts(getMore: true)
        
        self.noPostsString = "Speicher die deine Lieblingsposts um sie hier zu finden!"
        // navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func getPosts(getMore: Bool) {
        if let user = Auth.auth().currentUser {
                postHelper.getTheSavedPosts(getMore: getMore, whichPostList: .savedPosts, userUID: user.uid) { (posts, initialFetch)  in
                    
                    print("\(posts.count) neue dazu .InitialFetch: ",initialFetch)
                    
                    if initialFetch {   // Get the first batch of posts
                        self.posts = posts
                        self.tableView.reloadData()
                        
                        // I just load it for the first profilepicture and name
                        self.postHelper.getEvent(completion: { (post) in
                            self.tableView.reloadData()
                        })
                        
                        // remove ActivityIndicator incl. backgroundView
                        self.actInd.stopAnimating()
                        self.container.isHidden = true
                        
                        self.refreshControl?.endRefreshing()
                        
                    } else {    // Append the next batch to the existing
                        var indexes : [IndexPath] = [IndexPath]()
                        
                        for result in posts {
                            let row = self.posts.count
                            indexes.append(IndexPath(row: row, section: 0))
                            self.posts.append(result)
                        }
                        
                        if #available(iOS 11.0, *) {
                            self.tableView.performBatchUpdates({
                                self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                                self.tableView.insertRows(at: indexes, with: .bottom)
                            }, completion: { (_) in
                                self.fetchesPosts = false
                            })
                        } else {
                            // Fallback on earlier versions
                            self.tableView.beginUpdates()
                            self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
                            self.tableView.insertRows(at: indexes, with: .right)
                            self.tableView.endUpdates()
                            self.fetchesPosts = false
                        }
                    }
                    print("Jetzt haben wir \(self.posts.count)")
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
                if let reportVC = segue.destination as? MeldenViewController {
                    reportVC.post = chosenPost
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
