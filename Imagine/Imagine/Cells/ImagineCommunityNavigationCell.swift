//
//  ImagineCommunityNavigationCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 07.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

enum CommunityNavigationItem: CaseIterable {
    case proposals, website, feedback, moreInfo, settings
    
    var image: UIImage? {
        switch self {
        case .feedback:
            return UIImage(systemName: "hand.thumbsup.fill")
        case .moreInfo:
            return UIImage(named: "about")
        case .proposals:
            return UIImage(named: "idea")
        case .settings:
            return UIImage(named: "settings")
        case .website:
            return UIImage(named: "web")
        }
    }
}

protocol CommunityNavigationItemDelegate {
    func itemTapped(item: CommunityNavigationItem)
}

class ImagineCommunityNavigationCell: UICollectionViewCell {
        
    // MARK: - Variables
    
    static let identifier = "ImagineCommunityNavigationCell"
    
    var delegate: CommunityNavigationItemDelegate?
    
    let layout = UICollectionViewFlowLayout()
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupCollectionView() {
        addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SimpleCell.self, forCellWithReuseIdentifier: SimpleCell.identifier)
        
        layout.minimumLineSpacing = 20
        layout.scrollDirection = .horizontal
        collectionView.bounces = false
        
        collectionView.fillSuperview()
    }
}


extension ImagineCommunityNavigationCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        CommunityNavigationItem.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SimpleCell.identifier, for: indexPath) as? SimpleCell else { return UICollectionViewCell() }
        
        let item = CommunityNavigationItem.allCases[indexPath.item]
        cell.imageView.image = item.image
        
        return cell
    }
    
    // MARK: MultiPictureCollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        CGSize(width: collectionView.frame.width / 4.2, height: collectionView.frame.width / 4.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = CommunityNavigationItem.allCases[indexPath.item]
        delegate?.itemTapped(item: item)
    }
}


class SimpleCell: UICollectionViewCell {
    
    static let identifier = "SimpleCellIdentifier"
    
    let imageView = UIImageView()
    let containerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupLayout() {
        addSubview(containerView)
        containerView.fillSuperview(paddingTop: 5, paddingLeading: 5, paddingBottom: -5, paddingTrailing: -5)
        containerView.backgroundColor = .systemBackground
        
        contentView.clipsToBounds = false
        
        containerView.addSubview(imageView)
        imageView.clipsToBounds = true
        imageView.tintColor = .accentColor
        imageView.fillSuperview(paddingTop: 27, paddingLeading: 27, paddingBottom: -27, paddingTrailing: -27)
        imageView.contentMode = .scaleAspectFit
    }
    
    override func layoutSubviews() {
        containerView.setDefaultShadow(cornerRadius: containerView.frame.width / 2)
    }
}
