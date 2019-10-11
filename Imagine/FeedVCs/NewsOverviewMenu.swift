//
//  NewsOverviewMenu.swift
//  Imagine
//
//  Created by Malte Schoppe on 19.07.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//
import UIKit


class NewsOverviewMenu: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var posts = [BlogPost]()
    
    var feedTableVC: FeedTableViewController?
    
    let blackView = UIView()
    
    let tableView: UITableView = {
        let style = UITableView.Style.plain
        let tv = UITableView(frame: .zero, style: style)
        tv.backgroundColor = Constants.backgroundColorForTableViews
        return tv
    }()
    
    let cellId = "cellId"
    
    var settings: [Setting] = {
        return [Setting(type: .cancel)]
    }()
    
    func showView(navBarHeight: CGFloat) {
        //show menu
        
        if let window = UIApplication.shared.keyWindow {
            
            blackView.backgroundColor = UIColor(white: 0, alpha: 0.25)
            
            blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
            
            window.addSubview(blackView)
            
            window.addSubview(tableView)
            
            tableView.frame = CGRect(x: 10, y: navBarHeight+30, width: window.frame.width-20, height: 200)
            tableView.layer.cornerRadius = 10
            
            
            blackView.frame = window.frame
            blackView.alpha = 0
            
            tableView.reloadData()
            tableView.isHidden = false
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackView.alpha = 1
                self.tableView.frame = CGRect(x:10, y: navBarHeight+30, width: self.tableView.frame.width, height: self.tableView.frame.height)
                
            }, completion: nil)
        }
    }
    
    @objc func handleDismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            
            self.blackView.alpha = 0
            self.tableView.alpha = 0
            
        }, completion: { (_) in
            self.tableView.isHidden = true
            self.tableView.alpha = 1
          
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "NibBlogPostCell"
        
        tableView.register(UINib(nibName: "BlogPostCell", bundle: nil), forCellReuseIdentifier: identifier)
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? BlogCell {
            let blogPost = posts[indexPath.row]
            
            cell.post = blogPost
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 225
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let blogPost = posts[indexPath.row]
        
        self.feedTableVC?.blogPostSelected(blogPost: blogPost)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override init() {
        super.init()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(BlogCell.self, forCellReuseIdentifier: "BlogCell")
        
        self.tableView.activityStartAnimating()
        
        DataHelper().getData(get: .blogPosts) { (posts) in
            self.posts = posts as! [BlogPost]
            self.tableView.reloadData()
            self.tableView.activityStopAnimating()
        }
    }
    
}

