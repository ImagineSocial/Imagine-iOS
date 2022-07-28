//
//  PostCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import SDWebImage

protocol PostCellDelegate: class {
    func userTapped(post: Post)
    func reportTapped(post: Post)
    func thanksTapped(post: Post)
    func wowTapped(post: Post)
    func haTapped(post: Post)
    func niceTapped(post: Post)
    func linkTapped(post: Post)
    func factTapped(fact: Community)
    func collectionViewTapped(post: Post)
}

class PostCell : BaseFeedCell {
    
    //MARK:- IBOutlets
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellImageViewHeightConstraint: NSLayoutConstraint!

    
    //MARK:- Cell Lifecycle
    override func awakeFromNib() {
        selectionStyle = .none
        
        self.initiateCell()
                
        titleLabel.adjustsFontSizeToFitWidth = true
        
        cellImageView.layer.cornerRadius = 1
        cellImageView.isUserInteractionEnabled = true
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        self.cellImageView.addGestureRecognizer(pinch)
            
        // add corner radius on `contentView`
        cellImageView.layer.cornerRadius = 8
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
                
        cellImageView.sd_cancelCurrentImageLoad()
        cellImageView.image = nil
        
        resetValues()
    }
    
    //MARK:- Set Cell
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
            
            if let communityID = post.communityID {
                if post.community != nil {
                    setCommunity(for: post)
                } else {
                    getCommunity(with: communityID)
                }
            }
            
            titleLabel.text = post.title
            feedLikeView.setPost(post: post)
            
            if let imageURL = post.image?.url, let url = URL(string: imageURL), let cellImageView = cellImageView {
                cellImageView.sd_imageIndicator = SDWebImageActivityIndicator.grayLarge
                cellImageView.sd_imageIndicator?.startAnimatingIndicator()
                cellImageView.sd_setImage(with: url, placeholderImage: Constants.defaultImage, options: [], completed: nil)
            }
            
            setReportView(post: post, reportView: reportView, reportLabel: reportViewLabel, reportButton: reportViewButtonInTop, reportViewHeightConstraint: reportViewHeightConstraint)
        }
    }
    
    
    //MARK:- Pinch To Zoom
    @objc func pinch(sender:UIPinchGestureRecognizer) {
        // From this nice tutorial: https://medium.com/@jeremysh/instagram-pinch-to-zoom-pan-gesture-tutorial-772681660dfe
        if sender.state == .changed {
            guard let view = sender.view else {return}
            let pinchCenter = CGPoint(x: sender.location(in: view).x - view.bounds.midX,
                                      y: sender.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: sender.scale, y: sender.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            let currentScale = self.cellImageView.frame.size.width / self.cellImageView.bounds.size.width
            var newScale = currentScale*sender.scale
            if newScale < 1 {
                newScale = 1
                let transform = CGAffineTransform(scaleX: newScale, y: newScale)
                self.cellImageView.transform = transform
                sender.scale = 1
            }else {
                view.transform = transform
                sender.scale = 1
            }
        } else if sender.state == .ended {
            UIView.animate(withDuration: 0.3, animations: {
                self.cellImageView.transform = CGAffineTransform.identity
            })
        }
    }
}
