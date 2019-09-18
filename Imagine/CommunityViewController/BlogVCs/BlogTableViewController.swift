//
//  BlogTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.06.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage

class BlogTableViewController: UITableViewController {

    var postList = [BlogPost]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getData()
        self.view.activityStartAnimating()
    }
    
    func getData() {
        DataHelper().getData(get: .blogPosts) { (posts) in
            self.postList = posts as! [BlogPost]
            self.tableView.reloadData()
            self.view.activityStopAnimating()
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return postList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "NibBlogPostCell"
        
        tableView.register(UINib(nibName: "BlogPostCell", bundle: nil), forCellReuseIdentifier: identifier)
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? BlogCell {
            let blogPost = postList[indexPath.row]
            
            cell.post = blogPost
            
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 225
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let blogPost = postList[indexPath.row]
        
        performSegue(withIdentifier: "toBlogPost", sender: blogPost)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toBlogPost" {
            if let chosenPost = sender as? BlogPost {
                if let blogVC = segue.destination as? BlogPostViewController {
                    blogVC.blogPost = chosenPost
                }
            }
        }
    }
}


