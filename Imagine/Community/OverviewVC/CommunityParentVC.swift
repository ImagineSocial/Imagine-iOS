//
//  CommunityParentVC.swift
//  Imagine
//
//  Created by Don Malte on 19.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class CommunityParentVC: UIViewController {

    var community: Community?
    
    let layout = UICollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
    }
    
    private func setupCollectionView() {
        collectionView.register(CommunityChildCell.self, forCellWithReuseIdentifier: CommunityChildCell.identifier)
        collectionView.register(CommunityHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CommunityHeaderView.identifier)
        
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.contentInsetAdjustmentBehavior = .never
        
        collectionView.fillSuperview()
        collectionView.reloadData()
    }
}

// MARK: - CollectionView

extension CommunityParentVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommunityChildCell.identifier, for: indexPath) as? CommunityChildCell {
            cell.community = community
            cell.parentViewController = self
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        UIScreen.main.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        .init(width: collectionView.frame.width, height: 300)
    }
}


extension CommunityParentVC: CommunityHeaderDelegate {
    func segmentedControlTapped(index: Int, direction: UIPageViewController.NavigationDirection) {
        
    }

    func newPostTapped() {
        
    }

    func notLoggedIn() {
        
    }
}
