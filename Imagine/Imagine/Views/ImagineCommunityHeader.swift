//
//  CommunityHeader.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import DateToolsSwift

protocol ImagineCommunityHeaderDelegate {
    func expandButtonTapped()
}

class ImagineCommunityHeader: UICollectionReusableView {
    
    //MARK: - Elements
    
    let headerLabel = BaseLabel(font: UIFont.standard(with: .bold, size: 26))
    let expandButton = BaseButtonWithImage(image: UIImage(named: "down"), tintColor: .imagineColor)
    
    static let identifier = "ImagineCommunityHeader"
    
    //MARK: - Variables
    
    var isOpen: Bool? {
        didSet {
            if let isOpen = isOpen, isOpen {
                expandButton.setImage(UIImage(named: "up"), for: .normal)
            } else {
                expandButton.setImage(UIImage(named: "down"), for: .normal)
            }
        }
    }
    
    var expandView: () -> Void

    
    override init(frame: CGRect) {
        expandView = { }

        super.init(frame: .zero)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        expandView = { }
        
        super.init(coder: coder)
        
    }
    
    override func prepareForReuse() {
        expandButton.isHidden = true
    }
    

    
    private func setupConstraints() {
        addSubview(headerLabel)
        addSubview(expandButton)
        
        headerLabel.constrain(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, paddingTop: 40, paddingLeading: Constants.padding.standard, paddingBottom: -Constants.padding.small / 2)
        expandButton.constrain(centerY: headerLabel.centerYAnchor, leading: headerLabel.trailingAnchor, trailing: trailingAnchor, paddingLeading: 15, paddingTrailing: -15, width: Constants.size.button, height: Constants.size.button)
        
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside )
    }
    
    @objc func expandButtonTapped() {
        expandView()
    }
}
