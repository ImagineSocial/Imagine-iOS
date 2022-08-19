//
//  AddOnHeaderCollectionViewCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 27.08.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore

class AddOnHorizontalScrollCollectionViewCell: BaseAddOnCollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var headerImageView: DesignableImage!
    @IBOutlet weak var headerImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    
    @IBOutlet weak var thanksButton: DesignableButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var addOnDesignButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var containerView: UIView!
    
    // MARK: - Variables
    private let smallPostIdentifier = "SmallPostCell"
    private let smallFactIdentifier = "SmallFactCell"
    private let addTopicIdentifier = "AddTopicCell"
    
    private let itemCellWidth: CGFloat = 245
    private var itemCellsGap: CGFloat = 10
    
    var itemRow: Int?
    weak var delegate: AddOnCellDelegate?
    
    var addOn: AddOn? {
            didSet {
                guard let addOn = addOn else {
                    return
                }
                
                addOn.delegate = self
                
                if let imageURL = addOn.imageURL, let url = URL(string: imageURL) {
                    headerImageView.sd_setImage(with: url, completed: nil)
                } else {
                    headerImageViewHeight.constant = addOn.design == .youTubePlaylist ? 50 : 0
                }
                
                addOnDesignButton.isHidden = addOn.design != .youTubePlaylist
                
                descriptionLabel.text = addOn.description
                
                if let title = addOn.headerTitle {
                    titleLabel.text = title
                }
                
                collectionView.reloadData()
                
                if addOn.items.count == 0 {
                    addOn.getItems(postOnly: false)
                }
            }
    }
    
    // MARK: - Cell Lifecycle
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
        
        addOnDesignButton.imageView?.contentMode = .scaleAspectFill
        
        //DesignStuff
        containerView.layer.cornerRadius = cornerRadius
        contentView.layer.cornerRadius = cornerRadius
    }
    
    
    
    override func prepareForReuse() {
        self.addOn = nil
        collectionView.setContentOffset(CGPoint.zero, animated: false)  //Set collectionView to the beginning
                
        headerImageViewHeight.constant = 115
        addOnDesignButton.isHidden = true
        
        thanksButton.setTitle(nil, for: .normal)
        thanksButton.setImage(UIImage(named: "thanksButton"), for: .normal)
    }
    
    //MARK:- IBActions
    @IBAction func thanksButtonTapped(_ sender: Any) {
        guard let addOn = addOn else {
            return
        }
        
        self.thanksButton.setImage(nil, for: .normal)
        
        if let thanksCount = addOn.thanksCount {
            self.thanksButton.setTitle(String(thanksCount), for: .normal)
            addOn.thanksCount = thanksCount+1
        } else {
            self.thanksButton.setTitle(String(1), for: .normal)
            addOn.thanksCount = 1
        }
        self.thanksButton.isEnabled = false
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @IBAction func addOnDesignButtonTapped(_ sender: Any) {
        guard let addOn = addOn else {
            return
        }
        
        if let link = addOn.externalLink, let url = URL(string: link) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "https://www.youtube.com/channel/UCnplKle1yLH86hib4ZdKblQ/playlists") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - UICollectionView DataSource/ Delegate/ FlowLayout
extension AddOnHorizontalScrollCollectionViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let addOn = addOn else {
            print("Return wrong size in collectionviewintsableviewcell")
            return CGSize(width: 300, height: collectionView.frame.height)
        }
        
        if indexPath.item != addOn.items.count {
            let item = addOn.items[indexPath.item]
            if let fact = item.item as? Community {      // Fact
                if fact.displayOption == .topic {
                    return CGSize(width: 250, height: collectionView.frame.height)
                } else {
                    return CGSize(width: 300, height: collectionView.frame.height)
                }
            } else {        // Post
                return CGSize(width: itemCellWidth, height: collectionView.frame.height)
            }
        } else {        // AddItemCell
            return CGSize(width: 50, height: 50)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let info = addOn else { return 0 }
        
        return info.items.count+1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let addOn = addOn else {
            return UICollectionViewCell()
        }
        
        if indexPath.item != addOn.items.count {
            
            let item = addOn.items[indexPath.item]
            
            switch item.item {
            case let post as Post:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: smallPostIdentifier, for: indexPath) as? SmallPostCell {
                    
                    cell.loadPost(post: post)
                    
                    if let title = post.addOnTitle {
                        cell.postTitle = title
                    } else {
                        cell.postTitle = "gotcha" // I know, but there is so much to do
                    }
                    
                    return cell
                }
            case let community as Community:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: smallFactIdentifier, for: indexPath) as? SmallFactCell {
                    
                    if community.title != "" {
                        cell.community = community
                    } else {    // Not loaded yet
                        cell.communityID = community.id
                    }
                    
                    //                        if let title = community.addOnTitle {
                    //                            cell.postTitle = title
                    //                        } else {
                    //                            cell.postTitle = "gotcha"
                    //                        }
                    
                    
                    cell.setUI(displayOption: community.displayOption)
                    
                    return cell
                }
            default:
                break
            }
        } else {
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPost", for: indexPath) as? AddItemCollectionViewCell {
                
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let addOn = addOn else {
            return
        }
        
        if addOn.items.count != indexPath.item {
            
            let currentCell = collectionView.cellForItem(at: indexPath)
            
            if let guiltyCell = currentCell as? SmallFactCell, let community = guiltyCell.community {
                delegate?.itemTapped(item: community)
            } else if let diyCell = currentCell as? SmallPostCell, let post = diyCell.post {
                delegate?.itemTapped(item: post)
            }
        } else {
            // AddNewItem tapped
            delegate?.newPostTapped(addOn: addOn)
        }
    }
}

// MARK: - AddOnDelegate
extension AddOnHorizontalScrollCollectionViewCell: AddOnDelegate {
    func itemAdded(successfull: Bool) {
        print("not needed")
    }
    
    func fetchCompleted() {
        if let info = addOn {
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

// MARK: - AddItemCollectionViewCell
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
