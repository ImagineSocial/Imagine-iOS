//
//  TestVC.swift
//  Imagine
//
//  Created by Don Malte on 18.12.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class CommunityChildCell: UICollectionViewCell {
    
    static let identifier = "CommunityChildCell"
    
    var community: Community? {
        didSet {
            loadViewController()
        }
    }
    var parentViewController: UIViewController?
    
    let layout = UICollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    var communityVCs: [UIViewController]?
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupCollectionView() {
        collectionView.register(ContainerCommunityCell.self, forCellWithReuseIdentifier: ContainerCommunityCell.identifier)
        
        addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.isPagingEnabled = true
        collectionView.contentInsetAdjustmentBehavior = .never
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        collectionView.fillSuperview()
        collectionView.reloadData()
    }
    
    private func loadViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let addOnVC = storyboard.instantiateViewController(withIdentifier: "addOnCollectionVC") as? AddOnCollectionViewController
        let postVC = storyboard.instantiateViewController(withIdentifier: "postsOfFactVC") as? CommunityPostTableVC
        let discussionVC = storyboard.instantiateViewController(withIdentifier: "factParentVC") as? DiscussionParentVC
        
        guard let community = community, let addOnVC = addOnVC, let postVC = postVC else { return }

        addOnVC.community = community
        postVC.community = community
        
        communityVCs = [addOnVC, postVC]
        
        if community.displayOption == .discussion, let discussionVC = discussionVC {
            discussionVC.community = community
            
            communityVCs?.insert(discussionVC, at: 1)
        }
        
        collectionView.reloadData()
    }
}

// MARK: - CollectionView

extension CommunityChildCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("CommunityVCs: \(communityVCs?.count ?? 0)")
        return communityVCs?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let communityVCs = communityVCs, let parentViewController = parentViewController else {
            return UICollectionViewCell()
        }
        
        let vc = communityVCs[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ContainerCommunityCell.identifier, for: indexPath) as? ContainerCommunityCell {
            parentViewController.addChild(vc)
            vc.view.frame = cell.contentView.bounds
            cell.contentView.addSubview(vc.view)
            vc.didMove(toParent: parentViewController)
            
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
}


extension CommunityChildCell: CommunityHeaderDelegate {
    func segmentedControlTapped(index: Int, direction: UIPageViewController.NavigationDirection) {
        
    }

    func newPostTapped() {
        
    }

    func notLoggedIn() {
        
    }
}


class ContainerCommunityCell: UICollectionViewCell {
    
    static var identifier = "containerCommunityCell"
}
