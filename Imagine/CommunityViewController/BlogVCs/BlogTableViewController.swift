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
    let blogPostIdentifier = "NibBlogPostCell"
    let currentProjectsIdentifier = "CurrentProjectsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "BlogPostCell", bundle: nil), forCellReuseIdentifier: blogPostIdentifier)
        tableView.register(UINib(nibName: "CurrentProjectsCell", bundle: nil), forCellReuseIdentifier: currentProjectsIdentifier)
        
        getData()
        self.view.activityStartAnimating()
        tableView.separatorStyle = .none
    }
    
    func getData() {
        DataHelper().getData(get: .blogPosts) { (posts) in
            self.postList = posts as! [BlogPost]
            
            let first = BlogPost()
            first.isCurrentProjectsCell = true
            
            self.postList.insert(first, at: 0)
            
            self.tableView.reloadData()
            self.view.activityStopAnimating()
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return postList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let blogPost = postList[indexPath.row]
        
        if blogPost.isCurrentProjectsCell {
            if let cell = tableView.dequeueReusableCell(withIdentifier: currentProjectsIdentifier, for: indexPath) as? CurrentProjectsCell {
                
                cell.delegate = self
                
                return cell
            }
        } else {
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: blogPostIdentifier, for: indexPath) as? BlogCell {
                
                cell.post = blogPost
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let post = postList[indexPath.row]
        
        if post.isCurrentProjectsCell {
            return 290
        } else {
            return 225
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let blogPost = postList[indexPath.row]
        
        if !blogPost.isCurrentProjectsCell {
            performSegue(withIdentifier: "toBlogPost", sender: blogPost)
        }
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
        if segue.identifier == "linkTapped" {
            if let chosenLink = sender as? String {
                if let webVC = segue.destination as? WebViewController {
                    webVC.link = chosenLink
                }
            }
        }
    }
}

extension BlogTableViewController: CurrentProjectDelegate {
    func sourceTapped(link: String) {
        performSegue(withIdentifier: "linkTapped", sender: link)
    }

}


