//
//  CollectionViewInTableViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 06.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

protocol CollectionViewInTableViewCellDelegate {
    func itemTapped(item: Any)
    func newPostTapped(info: OptionalInformation)
}

class CollectionViewInTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate: CollectionViewInTableViewCellDelegate?
    
    var info: OptionalInformation? {
        didSet {
            
            showPost(info: info!)
        }
    }
    
    func showPost(info: OptionalInformation) {
        
        collectionView.reloadData()
    }
    
    let DIYCellIdentifier = "DIYCollectionViewCell"
    let whyGuiltyIdentifier = "WhyGuiltyCollectionViewCell"
    let tableViewIdentifier = "TableViewInCollectionViewCell"
    
    override func awakeFromNib() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "WhyGuiltyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: whyGuiltyIdentifier)
        collectionView.register(UINib(nibName: "DIYCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: DIYCellIdentifier)
        collectionView.register(UINib(nibName: tableViewIdentifier, bundle: nil), forCellWithReuseIdentifier: tableViewIdentifier)
        collectionView.register(UINib(nibName: "AddTopicCell", bundle: nil), forCellWithReuseIdentifier: "AddTopicCell")
        collectionView.register(AddItemCollectionViewCell.self, forCellWithReuseIdentifier: "AddPost")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
    }
}

extension CollectionViewInTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let info = info {
            if indexPath.item != info.items.count {
                switch info.type {
                case .diy:
                    return CGSize(width: 200, height: collectionView.frame.height)
                case .avoid:
                    return CGSize(width: 300, height: collectionView.frame.height)
                case .guilty:
                    return CGSize(width: 300, height: collectionView.frame.height)
                }
            } else {
                return CGSize(width: 50, height: 50)
            }
        }
        return CGSize(width: 300, height: collectionView.frame.height)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let info = info else { return 0 }
        
        if info.type == .avoid {
            return (info.items.count/4)+1
        } else {
            return info.items.count+1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let info = info {
            
            if indexPath.item != info.items.count {
                switch info.type {
                    
                case .diy:
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DIYCellIdentifier, for: indexPath) as? DIYCollectionViewCell {
                        
                        if let posts = info.items as? [Post] {
                            let post = posts[indexPath.row]
                            
                            cell.postID = post.documentID
                            if let title = post.addOnTitle {
                                cell.postTitle = title
                            }
                        }
                        
                        return cell
                    }
                case .guilty:
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: whyGuiltyIdentifier, for: indexPath) as? WhyGuiltyCollectionViewCell {
                        
                        if let facts = info.items as? [Fact] {
                            let fact = facts[indexPath.row]
                            
                            if fact.title != "" {   // Not loaded yet
                                cell.fact = fact
                            } else {
                                cell.factID = fact.documentID
                            }
                        }
                        
                        return cell
                    }
                case .avoid:
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tableViewIdentifier, for: indexPath) as? TableViewInCollectionViewCell {
                        
                        if let items = info.items as? [Company] {   // TO DO: Sort them in batches of 4!
                            cell.items = items
                        }
                        return cell
                    }
                }
            } else {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPost", for: indexPath) as? AddItemCollectionViewCell {
                    
                    return cell
                }
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let info = info {
            if info.items.count != indexPath.item {
//                let item = info.items[indexPath.item]
                
                // The Post/Fact gets fetched inside each cell, so the items list in this view is not complete
                
                let currentCell = collectionView.cellForItem(at: indexPath)
                if let guiltyCell = currentCell as? WhyGuiltyCollectionViewCell {
                    if let fact = guiltyCell.fact {
                        delegate?.itemTapped(item: fact)
                    }
                } else if let diyCell = currentCell as? DIYCollectionViewCell {
                    if let post = diyCell.post {
                        delegate?.itemTapped(item: post)
                    }
                }
            } else {
                // Add NewPost tapped
                delegate?.newPostTapped(info: info)
            }
        }
    }
}

class AddItemCollectionViewCell: UICollectionViewCell {
    
    override func layoutSubviews() {
        
        addSubview(addPostImageView)
        
        addPostImageView.widthAnchor.constraint(equalTo: widthAnchor, constant: -10).isActive = true
        addPostImageView.heightAnchor.constraint(equalTo: heightAnchor, constant: -10).isActive = true
        addPostImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5).isActive = true
        addPostImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
    }
    
    let addPostImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "AddPost-1")
        imageView.tintColor = .imagineColor
        
        return imageView
    }()
}

