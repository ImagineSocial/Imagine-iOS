//
//  PostVC+MultiPicCollectionView.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

//MARK: - MultiPictureCollectionView

extension PostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: MultiPictureCollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = imageURLs[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MultiImageCollectionCell.identifier, for: indexPath) as? MultiImageCollectionCell {
            
            if image == defaultLinkString {
                cell.image = UIImage(named: "default-link")
            } else {
                cell.imageURL = image
                cell.layoutIfNeeded()
            }
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: MultiPictureCollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if post.type == .panorama {
            var height = post.mediaHeight
            if height > panoramaHeightMaximum {
                height = panoramaHeightMaximum
            }
            let width = post.mediaWidth
            
            let ratio = width/post.mediaHeight
            let newWidth = ratio*height
            
            let panoSize = CGSize(width: newWidth, height: height)
            return panoSize
        }
        let size = CGSize(width: imageCollectionView.frame.width, height: imageCollectionView.frame.height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = imageURLs[indexPath.item]
        
        let pinchVC = PinchToZoomViewController()
        pinchVC.imageURL = image
        pinchVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
}
