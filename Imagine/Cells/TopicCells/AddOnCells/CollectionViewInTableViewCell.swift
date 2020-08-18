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
    func saveItems(section: Int, item: Any) //Return the fetched Posts
}

class CollectionViewInTableViewCell: UITableViewCell, OptionalInformationDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backgroundBorderView: DesignablePopUp!
    
    var delegate: CollectionViewInTableViewCellDelegate?
    var isAddOnStoreCell = false
    
    var section: Int?
    
    var info: OptionalInformation? {
        didSet {
            if let info = info {
                info.delegate = self
                if info.items.count == 0 {
                    collectionView.reloadData() // If the cell got old Data in it
//                    print("Would get the items now")
                    info.getItems()
                } else {
                    print("Already Got Items")
                    collectionView.reloadData()
                }
            } else {
                print("No Info we got")
            }
        }
    }
    
    let DIYCellIdentifier = "SmallPostCell"
    let whyGuiltyIdentifier = "SmallFactCell"
    let tableViewIdentifier = "TableViewInCollectionViewCell"
    
    let itemCellWidth: CGFloat = 245
    var itemCellsGap: CGFloat = 10
    
    override func awakeFromNib() {
        
        backgroundBorderView.layer.borderWidth = 0.5
        if #available(iOS 13.0, *) {
            backgroundBorderView.layer.borderColor = UIColor.separator.cgColor
        } else {
            backgroundBorderView.layer.borderColor = UIColor.lightGray.cgColor
        }
        
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
    
    override func prepareForReuse() {
        self.info = nil
        collectionView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    // OptionalInformationDelegate
    func done() {
        if let info = info {
            if let orderList = info.itemOrder { // If an itemOrder exists (set in addOn-settings), order according to it
                let items = info.items
                DispatchQueue.global(qos: .default).async {
                    let sorted = items.compactMap { obj in
                        orderList.index(of: obj.documentID).map { idx in (obj, idx) }
                    }.sorted(by: { $0.1 < $1.1 } ).map { $0.0 }
                    
                    info.items = sorted
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            } else {
                collectionView.reloadData()
            }
        }
    }
    
}

extension CollectionViewInTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isAddOnStoreCell {
            let width = (collectionView.frame.width/2)-15   //15 is spacing +insets/2
            return CGSize(width: width, height: collectionView.frame.height)
        }
        
        if let info = info {
            if indexPath.item != info.items.count {
                let item = info.items[indexPath.item]
                if let fact = item.item as? Fact {      // Fact
                    if fact.displayOption == .topic {
                        return CGSize(width: 250, height: collectionView.frame.height)
                    } else {
                        return CGSize(width: 300, height: collectionView.frame.height)
                    }
                } else {        // Post
                    return CGSize(width: itemCellWidth, height: collectionView.frame.height)
//                    return CGSize(width: collectionView.frame.width-40, height: collectionView.frame.height)
                }
            } else {        // AddItemCell
                return CGSize(width: 50, height: 50)
            }
        }
        
        print("Return wrong size in collectionviewintsableviewcell")
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
                
                if let post = item.item as? Post {
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DIYCellIdentifier, for: indexPath) as? SmallPostCell {
                        
                        cell.delegate = self
                        if post.documentID != "" {
                            cell.loadPost(postID: post.documentID, isTopicPost: post.isTopicPost)
                        } else {    //NewAddOnTableVC
                            cell.post = post
                        }
                        
                        if let title = post.addOnTitle {
                            cell.postTitle = title
                        } else {
                            cell.postTitle = "gotcha" // I know, but there is so much to do
                        }
                        
                        return cell
                    }
                } else if let fact = item.item as? Fact {
                    
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: whyGuiltyIdentifier, for: indexPath) as? SmallFactCell {
                        
                        if fact.title != "" {
                            cell.fact = fact
                        } else {    // Not loaded yet
                            cell.factID = fact.documentID
                        }
                        
                        if let title = fact.addOnTitle {
                            cell.postTitle = title
                        } else {
                            cell.postTitle = "gotcha"
                        }
                        
                        
                        cell.setUI(displayOption: fact.displayOption)
                        
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
                // AddNewItem tapped
                delegate?.newPostTapped(addOnDocumentID: info.documentID)
            }
        }
    }
}

extension CollectionViewInTableViewCell: SmallPostCellDelegate {
    func sendItem(item: Any) {
        if let section = section {
            delegate?.saveItems(section: section, item: item)
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

