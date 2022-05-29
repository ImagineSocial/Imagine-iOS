//
//  NewPostVC+CollectionView.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

extension NewPostVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func setupCollectionView() {
        collectionView.register(NewPostTitleCell.self, forCellWithReuseIdentifier: NewPostTitleCell.identifier)
        collectionView.register(NewPostDescriptionCell.self, forCellWithReuseIdentifier: NewPostDescriptionCell.identifier)
        collectionView.register(NewPostLinkCell.self, forCellWithReuseIdentifier: NewPostLinkCell.identifier)
        collectionView.register(NewPostPictureCell.self, forCellWithReuseIdentifier: NewPostPictureCell.identifier)
        collectionView.register(NewPostOptionCell.self, forCellWithReuseIdentifier: NewPostOptionCell.identifier)
        collectionView.register(NewPostLocationCell.self, forCellWithReuseIdentifier: NewPostLocationCell.identifier)
        collectionView.register(NewPostLinkCommunityCell.self, forCellWithReuseIdentifier: NewPostLinkCommunityCell.identifier)
        
        collectionView.register(NewPostHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NewPostHeader.identifier)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = .init(top: 20, left: 0, bottom: 75, right: 0)
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            layout.headerReferenceSize = CGSize(width: collectionView.frame.width, height: 70)
        }
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        collectionView.reloadData()
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = collectionItems[indexPath.item]
        
        switch item {
        case .title:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostTitleCell.identifier, for: indexPath) as? NewPostTitleCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                return cell
            }
        case .description:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostDescriptionCell.identifier, for: indexPath) as? NewPostDescriptionCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                return cell
            }
        case .link:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostLinkCell.identifier, for: indexPath) as? NewPostLinkCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                return cell
            }
        case .picture:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostPictureCell.identifier, for: indexPath) as? NewPostPictureCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                return cell
            }
        case .options:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostOptionCell.identifier, for: indexPath) as? NewPostOptionCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                return cell
            }
        case .location:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostLocationCell.identifier, for: indexPath) as? NewPostLocationCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                return cell
            }
        case .linkCommunity:
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewPostLinkCommunityCell.identifier, for: indexPath) as? NewPostLinkCommunityCell {
                cell.delegate = self
                cell.maxWidth = collectionView.frame.width
                
                //Settings when this view is called from inside the community
                if comingFromPostsOfFact || comingFromAddOnVC {
                    
                    cell.cancelLinkedCommunityButton.isEnabled = false
                    cell.cancelLinkedCommunityButton.alpha = 0.5
                    cell.distributionInformationLabel.text = "Community"
                }
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.endEditing(true)
        removeTipViews()
    }
}

extension NewPostVC {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NewPostHeader.identifier, for: indexPath) as? NewPostHeader {
            view.segmentedControlView.delegate = self
            
            return view
        }
        
        return UICollectionReusableView()
    }
}
