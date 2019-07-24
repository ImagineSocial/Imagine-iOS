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
    }
    
    func getData() {
        DataHelper().getData(get: "blogPosts") { (posts) in
            self.postList = posts as! [BlogPost]
            self.tableView.reloadData()
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

class BlogCell : UITableViewCell {
    @IBOutlet weak var headerLabel:UILabel!
    @IBOutlet weak var bodyLabel:UILabel!
    @IBOutlet weak var createDateLabel:UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    
    var post:BlogPost? {
        didSet {
            if let post = post {
                headerLabel.text = post.title
                bodyLabel.text = post.subtitle
                createDateLabel.text = post.createDate
                categoryLabel.text = "Thema: \(post.category)"
                nameLabel.text = post.poster
                
                if let url = URL(string: post.profileImageURL) {
                    profileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
                }
                
                profileImageView.layer.cornerRadius = profileImageView.frame.width/2
                profileImageView.clipsToBounds = true
            }
        }
    }
    
}
