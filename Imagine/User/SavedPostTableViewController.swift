//
//  SavedPostTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 16.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

// Set getMore in UserPostHelper!
class SavedPostTableViewController: BaseFeedTableViewController {
    
    let userPostHelper = UserPostHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getPosts(getMore: true)
        // navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func getPosts(getMore: Bool) {
        if let user = Auth.auth().currentUser {
            userPostHelper.getPosts(whichPostList: .savedPosts, userUID: user.uid) { (posts) in
                self.posts = posts
                self.posts.sort(by: { $0.createTime.compare($1.createTime) == .orderedDescending })
                self.tableView.reloadData()
                
                PostHelper().getEvent(completion: { (_) in
                    // Lade das eigentlich nur, damit der die Profilbilder und so richtig lädt
                    self.tableView.reloadData()
                })
                
                // remove ActivityIndicator incl. backgroundView
                self.actInd.stopAnimating()
                self.container.isHidden = true
                
                self.refreshControl?.endRefreshing()
                
            }
        }
    }
    
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        // Takes care of toggling the button's title.
//        super.setEditing(!isEditing, animated: true)
//        
//        // Toggle table view editing.
//        tableView.setEditing(!tableView.isEditing, animated: true)
//    }

}
