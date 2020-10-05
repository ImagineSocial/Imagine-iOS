//
//  AddOnHeaderCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol AddOnCellDelegate {
    func showDescription()
    func settingsTapped(itemRow: Int)
    func thanksTapped(info: OptionalInformation)
    
    //CollectionViewDelegate
    func itemTapped(item: Any)
    func newPostTapped(addOnDocumentID: String)
}

class AddOnHorizontalScrollCollectionViewCell: BaseAddOnCollectionViewCell {
    
    @IBOutlet weak var headerImageView: DesignableImage!
    @IBOutlet weak var headerImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var containerView: UIView!
    
    let smallPostIdentifier = "SmallPostCell"
    let smallFactIdentifier = "SmallFactCell"
    let addTopicIdentifier = "AddTopicCell"
    
    let itemCellWidth: CGFloat = 245
    var itemCellsGap: CGFloat = 10
    
    var itemRow: Int?
    var delegate: AddOnCellDelegate?
    
    var info: OptionalInformation? {
            didSet {
                if let info = info {
                    info.delegate = self
                    
                    if let imageURL = info.imageURL {
                        if let url = URL(string: imageURL) {
                            headerImageView.sd_setImage(with: url, completed: nil)
                        }
                    } else {
                        headerImageViewHeight.constant = 0
                    }
                    
                    
                    descriptionLabel.text = info.description
                    
                    if let title = info.headerTitle {
                        titleLabel.text = title
                    }
                    
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
    
    override func awakeFromNib() {
        
        //CollectionView
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UINib(nibName: "SmallFactCell", bundle: nil), forCellWithReuseIdentifier: smallFactIdentifier)
        collectionView.register(UINib(nibName: "SmallPostCell", bundle: nil), forCellWithReuseIdentifier: smallPostIdentifier)
        collectionView.register(UINib(nibName: "AddTopicCell", bundle: nil), forCellWithReuseIdentifier: addTopicIdentifier)
        collectionView.register(AddItemCollectionViewCell.self, forCellWithReuseIdentifier: "AddPost")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        //DesignStuff
        containerView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerRadius = cornerRadius
    }
    
    
    
    override func prepareForReuse() {
        self.info = nil
        collectionView.setContentOffset(CGPoint.zero, animated: false)  //Set collectionView to the beginning
                
        headerImageViewHeight.constant = 115
        
        thanksButton.setTitle(nil, for: .normal)
        thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
    }
    
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let info = info {
            self.thanksButton.setImage(nil, for: .normal)
            
            if let thanksCount = info.thanksCount {
                self.thanksButton.setTitle(String(thanksCount), for: .normal)
                info.thanksCount = thanksCount+1
            } else {
                self.thanksButton.setTitle(String(1), for: .normal)
                info.thanksCount = 1
            }
            self.thanksButton.isEnabled = false
//            delegate?.thanksTapped(info: info)
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

extension AddOnHorizontalScrollCollectionViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
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
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: smallPostIdentifier, for: indexPath) as? SmallPostCell {
                        
//                        cell.delegate = self
                        if post.documentID != "" {
                            cell.loadPost(post: post)
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
                    
                    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: smallFactIdentifier, for: indexPath) as? SmallFactCell {
                        
                        if fact.title != "" {
                            cell.fact = fact
                        } else {    // Not loaded yet
                            cell.unloadedFact = fact
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

extension AddOnHorizontalScrollCollectionViewCell: OptionalInformationDelegate {
    func fetchCompleted() {
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
                self.collectionView.reloadData()
            }
        }
    }
}

