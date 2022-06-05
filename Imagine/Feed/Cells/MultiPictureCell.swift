//
//  MultiPictureCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 22.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class MultiPictureCell: BaseFeedCell {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pictureCountLabel: UILabel!
    @IBOutlet weak var multiPictureCollectionViewHeightConstraint: NSLayoutConstraint!
    
    //MARK: - Variables
    
    private var images: [String]?
    
    private var pageControlHeightValue: CGFloat = 15
    
    override var post: Post? {
        didSet {
            if let post = post {
                setCell()
                
                if post.type == .multiPicture {
                    if let images = post.images {
                        
                        self.images = images.map({ $0.url })
                        self.pictureCountLabel.text = "1/\(images.count)"
                        
                        collectionView.isPagingEnabled = true
                        collectionView.reloadData()
                    }
                } else if post.type == .panorama, let imageURL = post.image?.url {
                    self.images = [imageURL]
                    self.pictureCountLabel.text = "< - >"
                    
                    collectionView.isPagingEnabled = false
                    collectionView.reloadData()
                }
            }
        }
    }
    
    
    //MARK: - Cell Lifecycle
    
    override func awakeFromNib() {
        
        self.initiateCell()
        
        collectionView.register(MultiImageCollectionCell.self, forCellWithReuseIdentifier: MultiImageCollectionCell.identifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        collectionView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                
        collectionView.setContentOffset(CGPoint.zero, animated: false)  //Set collectionView to the beginning
        
        resetValues()
    }
    
    //MARK: - Set Cell
    
    override func setCell() {
        super.setCell()
        
        if let post = post {
            if ownProfile { // Set in the UserFeedTableViewController DataSource
                
                if let _ = cellStyle {
                    print("Already Set")
                } else {
                    cellStyle = .ownCell
                    setOwnCell(post: post)
                }
            } else {
                setDefaultButtonImages()
            }
            
            if post.user == nil {
                if post.anonym {
                    self.setUser()
                } else {
                    self.checkForUser()
                }
            } else {
                setUser()
            }
            
            if let fact = post.community {
                                
                if fact.title == "" {
                    if fact.beingFollowed {
                        self.getCommunity(beingFollowed: true)
                    } else {
                        self.getCommunity(beingFollowed: false)
                    }
                } else {
                    self.setCommunity(post: post)
                }
            }
            
            titleLabel.text = post.title
            feedLikeView.setPost(post: post)
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
}

//MARK: - UICollectionView DataSource/ Delegate/ FlowLayout

extension MultiPictureCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let images = self.images {
            return images.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let images = self.images {
            let image = images[indexPath.item]
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MultiImageCollectionCell.identifier, for: indexPath) as? MultiImageCollectionCell {
                
                cell.imageURL = image
                
                return cell
            }
        }

        return UICollectionViewCell()
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let post = post, let image = post.image, post.type == .panorama else {
            
            return .init(width: collectionView.frame.width, height: collectionView.frame.height)
        }
        
        let ratio = image.width / image.height
        let collectionViewHeight = Constants.Numbers.panoramaCollectionViewHeight
        
        let newWidth = collectionViewHeight * ratio
        
        collectionView.setContentOffset(CGPoint(x: newWidth / 2, y: 0), animated: false)
        
        return CGSize(width: newWidth, height: collectionViewHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let post = post, post.type != .panorama, let indexPath = collectionView.indexPathsForVisibleItems.first, let images = post.images else {
            //no need for the display in a panorama picture
            return
        }
        
        self.pictureCountLabel.text = "\(indexPath.row + 1)/\(images.count)"
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let post = post {
            delegate?.collectionViewTapped(post: post)
        }
    }
}
