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
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.frame.width / 4.2
        
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = CommunityNavigationItem.allCases[indexPath.item]
        delegate?.itemTapped(item: item)
    }
}


class SimpleCell: UICollectionViewCell {
    
    static let identifier = "SimpleCellIdentifier"
    
    let imageView = BaseImageView(image: nil)
    let containerView = UIView()
    
    var size: CGFloat? {
        didSet {
            guard let size = size else { return }
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: size),
                imageView.heightAnchor.constraint(equalToConstant: size)
            ])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        setupLayout()
        layoutIfNeeded()
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
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        imageView.constrain(centerX: containerView.centerXAnchor, centerY: containerView.centerYAnchor, width: 28, height: 28)
        
        imageView.clipsToBounds = true
        imageView.tintColor = .accentColor
        imageView.contentMode = .scaleAspectFit
    }
    
    override func layoutSubviews() {
        containerView.setDefaultShadow(cornerRadius: containerView.frame.width / 2)
    }
}
