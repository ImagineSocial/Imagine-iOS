//
//  NewPostHeader.swift
//  Imagine
//
//  Created by Don Malte on 10.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostHeader: UICollectionReusableView {
    
    static let identifier = "NewPostHeader"
    
    let backgroundView = BaseView(backgroundColor: .secondarySystemBackground)
    let segmentedControlView = BaseSegmentedControlView(items: [Strings.text, Strings.picture, Strings.link], tintColor: .imagineColor, font: .standard(with: .medium, size: 15))

    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        addSubview(backgroundView)
        backgroundView.addSubview(segmentedControlView)
        
        backgroundView.constrain(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, paddingTop: 7.5, paddingLeading: 10, paddingBottom: -20, paddingTrailing: -10, height: 35)
        segmentedControlView.constrain(top: backgroundView.topAnchor, leading: backgroundView.leadingAnchor, bottom: backgroundView.bottomAnchor, trailing: backgroundView.trailingAnchor, paddingTop: 5, paddingLeading: 5, paddingBottom: -10, paddingTrailing: -5)
        
        backgroundView.layer.cornerRadius = 10
    }
}
