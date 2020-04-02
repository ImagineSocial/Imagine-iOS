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
    func newPostTapped(addOnDocumentID: String)
}

class CollectionViewInTableViewCell: UITableViewCell, OptionalInformationDelegate {
    func done() {
        collectionView.reloadData()
    }
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate: CollectionViewInTableViewCellDelegate?
    
    var info: OptionalInformation? {
        didSet {
            if let info = info {
                info.delegate = self
                info.getItems()
            } else {
                print("No Info we got")
            }
        }
    }
    
    let DIYCellIdentifier = "SmallPostCollectionCell"
    let whyGuiltyIdentifier = "SmallFactCell"
    let tableViewIdentifier = "TableViewInCollectionViewCell"
    
    override func awakeFromNib() {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "SmallFactCell", bundle: nil), forCellWithReuseIdentifier: whyGuiltyIdentifier)
        collectionView.register(UINib(nibName: "SmallPostCell", bundle: nil), forCellWithReuseIdentifier: DIYCellIdentifier)
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
                let item = info.items[indexPath.item]
                if let _ = item as? Fact {
                    return CGSize(width: 300, height: collectionView.frame.height)
                } else {
                    return CGSize(width: 200, height: collectionView.frame.height)
                }
            } else {
                return CGSize(width: 50, height: 50)
            }
        }
        return CGSize(width: 300, height: collectionView.frame.height)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let info = info else { return 0 }
        
        return info.items.count+1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let info = info {
            
            if indexPath.item != info.items.count {
                
                let item = info.items[indexPath.item]
                
                if let post = item as? Post {
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DIYCellIdentifier, for: indexPath) as? SmallPostCell {
                        
                        cell.postID = post.documentID
                        
                        if let title = post.addOnTitle {
                            cell.postTitle = title
                        }
                        
                        return cell
                    }
                } else if let fact = item as? Fact {
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: whyGuiltyIdentifier, for: indexPath) as? SmallFactCell {
                        
                        if fact.title != "" {   // Not loaded yet
                            cell.fact = fact
                        } else {
                            cell.factID = fact.documentID
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
                if let guiltyCell = currentCell as? SmallFactCell {
                    if let fact = guiltyCell.fact {
                        delegate?.itemTapped(item: fact)
                    }
                } else if let diyCell = currentCell as? SmallPostCell {
                    if let post = diyCell.post {
                        delegate?.itemTapped(item: post)
                    }
                }
            } else {
                // Add NewPost tapped
                delegate?.newPostTapped(addOnDocumentID: info.documentID)
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

