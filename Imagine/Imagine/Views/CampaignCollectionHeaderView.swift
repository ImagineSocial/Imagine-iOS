//
//  CampaignCollectionHeaderView.swift
//  Imagine
//
//  Created by Malte Schoppe on 12.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

protocol CampaignCollectionHeaderDelegate {
    func newCampaignTapped()
    func segmentControlChanged(segmentControl: UISegmentedControl)
}

class CampaignCollectionHeaderView: UICollectionReusableView {

    static let identifier = "campaignHeader"
    
    let descriptionLabel = BaseTextLabel(text: Strings.proposalIntroDescription, numberOfLines: 0)
    let shareButton = BaseButtonWithText(text: Strings.proposalButtonText, titleColor: .imagineColor, cornerRadius: Constants.cellCornerRadius, borderColor: UIColor.imagineColor.cgColor)
    let segmentedControl = BaseSegmentedControl(items: [Strings.proposalOpen, Strings.proposalFinished])
        
    var delegate: CampaignCollectionHeaderDelegate?
    
    //MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        addSubview(descriptionLabel)
        addSubview(shareButton)
        addSubview(segmentedControl)
        shareButton.addTarget(self, action: #selector(shareIdeaTapped), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        
        descriptionLabel.constrain(top: topAnchor, leading: leadingAnchor, trailing: trailingAnchor, paddingTop: Constants.padding.standard, paddingLeading: Constants.padding.standard, paddingTrailing: -Constants.padding.standard)
        shareButton.constrain(top: descriptionLabel.bottomAnchor, leading: descriptionLabel.leadingAnchor, bottom: bottomAnchor, paddingTop: Constants.padding.standard, paddingBottom: -30, width: 130, height: 35)
        segmentedControl.constrain(centerY: shareButton.centerYAnchor, trailing: descriptionLabel.trailingAnchor, width: 160, height: 30)
    }
    
    
    @objc func shareIdeaTapped(_ sender: Any) {
        delegate?.newCampaignTapped()
    }
    
    @objc func segmentControlChanged() {
        delegate?.segmentControlChanged(segmentControl: segmentedControl)
    }
}

