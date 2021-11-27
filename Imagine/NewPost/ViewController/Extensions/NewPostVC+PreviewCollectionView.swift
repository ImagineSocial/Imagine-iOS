//
//  NewPostVC+PreviewCollectionView.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

extension NewPostViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func setupPreviewCollectionView() {

        pictureView.previewCollectionView.register(UINib(nibName: "MultiPictureCollectionCell", bundle: nil), forCellWithReuseIdentifier: identifier)
        
        pictureView.previewCollectionView.dataSource = self
        pictureView.previewCollectionView.delegate = self
        
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        pictureView.previewCollectionView.setCollectionViewLayout(layout, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previewPictures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = previewPictures[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? MultiImageCollectionCell {
            
            cell.image = image
            cell.layoutIfNeeded()
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = CGSize(width: pictureView.previewCollectionView.frame.width, height: pictureView.previewCollectionView.frame.height)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = previewPictures[indexPath.item]
        
        let pinchVC = PinchToZoomViewController()
        pinchVC.image = image
        pinchVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(pinchVC, animated: true)
    }
    
//    If we implement a pageControl
//            func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//                if let indexPath = collectionView.indexPathsForVisibleItems.first {
//                    pageControl.currentPage = indexPath.row
//                }
//            }
}

