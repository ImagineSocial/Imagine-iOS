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
        // #warning Incomplete implementation, return the number of rows
        return postList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "BlogCell", for: indexPath) as? BlogCell {
            let post = postList[indexPath.row]
            
            cell.headerLabel.text = post.title
            cell.bodyLabel.text = post.subtitle
            cell.createDateLabel.text = post.createDate
            cell.categoryLabel.text = "Thema: \(post.category)"
            cell.nameLabel.text = post.poster
            
            if let url = URL(string: post.profileImageURL) {
                cell.profileImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default-user"), options: [], completed: nil)
            }
            
            cell.profileImageView.layer.cornerRadius = cell.profileImageView.frame.width/2
            cell.profileImageView.clipsToBounds = true
            
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
    
    
}
