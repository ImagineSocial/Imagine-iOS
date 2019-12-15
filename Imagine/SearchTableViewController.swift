//
//  SearchTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 11.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController {

    var postResults: [Post]?
    var userResults: [User]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(SearchUserCell.self, forCellReuseIdentifier: "SearchUserCell")
        tableView.register(SearchPostCell.self, forCellReuseIdentifier: "SearchPostCell")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let users = userResults {
            print("Das sind die Resultate: \(users.count)")
            return users.count
        }
        if let posts = postResults {
            print("Das sind die Resultate: \(posts.count)")
            return posts.count
        }
        
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let posts = postResults {
            let post = posts[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchPostCell", for: indexPath) as? SearchPostCell {

                cell.post = post
                
                return cell
            }

        }
        
        if let users = userResults {
            let user = users[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserCell", for: indexPath) as? SearchUserCell {

                cell.user = user
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    

    deinit {
        print("Jetzt wird gedeinit")
    }
    
}
