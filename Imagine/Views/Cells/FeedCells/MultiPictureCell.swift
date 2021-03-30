//
//  MultiPictureCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 22.01.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

class MultiPictureCell: BaseFeedCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var pictureCountLabel: UILabel!
    @IBOutlet weak var multiPictureCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageControlHeight: NSLayoutConstraint!
    
    //MARK:- Variables
    private let identifier = "MultiPictureCell"
    private var images: [String]?
    
    private var pageControlHeightValue: CGFloat = 15
    
    override var post: Post? {
        didSet {
            if let post = post {
                setCell()
                
                if post.type == .multiPicture {
                    if let images = post.imageURLs {
                        
                        self.images = images
                        self.pageControl.numberOfPages = images.count
                        self.pictureCountLabel.text = "1/\(images.count)"
                        
                        collectionView.isPagingEnabled = true
                        collectionView.reloadData()
                    }
                } else if post.type == .panorama {
                    self.images = [post.imageURL]
                    self.pictureCountLabel.text = "< - >"
                    
                    pageControlHeight.constant = 6
                    pageControl.isHidden = true
                    collectionView.isPagingEnabled = false
                    collectionView.reloadData()
                }
            }
        }
    }
    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        
        self.initiateCell()
        
        collectionView.register(UINib(nibName: "MultiPictureCollectionCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        collectionView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                
        pageControlHeight.constant = pageControlHeightValue
        pageControl.isHidden = false
        pageControl.currentPage = 0
        
        collectionView.setContentOffset(CGPoint.zero, animated: false)  //Set collectionView to the beginning
        
        resetValues()
    }
    
    //MARK:- Set Cell
    override func setCell() {
        if let post = post {
            feedUserView.delegate = self
            
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
            
            if post.user.displayName == "" {
                if post.anonym {
                    self.setUser()
                } else {
                    self.getUser()
                }
            } else {
                setUser()
            }
            
            if let fact = post.fact {
                                
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
            descriptionPreviewLabel.text = post.description
            commentCountLabel.text = String(post.commentCount)
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    //MARK:- IBActions
    @IBAction func thanksButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: thanksButton)
        }
    }
    
    @IBAction func wowButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: wowButton)
        }
    }
    
    @IBAction func haButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: haButton)
        }
    }
    
    @IBAction func niceButtonTapped(_ sender: Any) {
        if let post = post {
            registerVote(post: post, button: niceButton)
        }
    }
}

//MARK:- UICollectionView DataSource/ Delegate/ FlowLayout
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
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? MultiImageCollectionCell {
                
                cell.imageURL = image
                
                return cell
            }
        }

        return UICollectionViewCell()
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let post = post {
            if post.type == .panorama {
                let ratio = post.mediaWidth/post.mediaHeight
                let collectionViewHeight = Constants.Numbers.panoramaCollectionViewHeight
                
                let newWidth = collectionViewHeight * ratio
                
                collectionView.setContentOffset(CGPoint(x: newWidth/2, y: 0), animated: false)
                
                return CGSize(width: newWidth, height: collectionViewHeight)
            }
        }
        let size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return size
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let post = post, post.type == .panorama {
            //no need for the display in a panorama picture
            return
        }
        
        if let indexPath = collectionView.indexPathsForVisibleItems.first {
            pageControl.currentPage = indexPath.row
            
            self.pictureCountLabel.text = "\(pageControl.currentPage+1)/\(pageControl.numberOfPages)"
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let post = post {
            delegate?.collectionViewTapped(post: post)
        }
    }
}


//MARK:- MultiImageCollectionCell
class MultiImageCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var collectionImageView: UIImageView!
    
    var image: UIImage? {
        didSet {
            if let image = image {
                collectionImageView.image = image
            }
        }
    }
    var imageURL: String? {
        didSet {
            if let imageURL = imageURL {
                
                if let url = URL(string: imageURL) {
                    collectionImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "default"), options: [], completed: nil)
                }
            }
        }
    }

    
}
