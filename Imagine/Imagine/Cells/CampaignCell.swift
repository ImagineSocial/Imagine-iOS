//
//  CampaignCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 29.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class CampaignCell: UICollectionViewCell {
    
    let containerView = BaseView()
    let headerLabel = BaseLabel(font: UIFont.getStandardFont(with: .semibold, size: 16))
    let descriptionLabel = BaseTextLabel(font: UIFont.getStandardFont(with: .medium, size: 14))
    let campaignDateLabel = BaseLabel(font: UIFont.getStandardFont(with: .regular, size: 12))
    let categoryLabel = BaseLabel(font: UIFont.getStandardFont(with: .medium, size: 12))
    let separatorView = HairlineView()
    
    var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        
        return progressView
    }()
    
    lazy var bottomStackView = BaseStackView(subviews: [categoryLabel, campaignDateLabel, UIView()], spacing: 10, axis: .horizontal)
    
    
    //MARK: - Variables
    
    static let identifier = "campaignCell"
    
    var campaign:Campaign? {
        didSet {
            if let campaign = campaign {
                
                headerLabel.text = campaign.title
                descriptionLabel.text = campaign.cellText
                campaignDateLabel.text = campaign.createDate
                
                let progress: Float = Float(campaign.supporter) / (Float(campaign.opposition) + Float(campaign.supporter))
                progressView.setProgress(progress, animated: true)
                
                if let category = campaign.category {
                    categoryLabel.text = category.title
                }
            }
        }
    }
    
    //MARK: - Cell Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupConstraints()
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupConstraints() {
        addSubview(containerView)
        containerView.addSubview(headerLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(separatorView)
        containerView.addSubview(bottomStackView)
        headerLabel.adjustsFontSizeToFitWidth = true
        
        containerView.fillSuperview()
        headerLabel.constrain(top: containerView.topAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, paddingTop: Constants.padding.innerCell, paddingLeading: Constants.padding.innerCell, paddingTrailing: -Constants.padding.innerCell, height: 30)
        descriptionLabel.constrain(top: headerLabel.bottomAnchor, leading: headerLabel.leadingAnchor, trailing: headerLabel.trailingAnchor, paddingTop: Constants.padding.standard / 2)
        separatorView.constrain(top: descriptionLabel.bottomAnchor, leading: descriptionLabel.leadingAnchor, trailing: descriptionLabel.trailingAnchor, paddingTop: Constants.padding.standard / 2, height: 1)
        bottomStackView.constrain(top: separatorView.bottomAnchor, leading: descriptionLabel.leadingAnchor, bottom: containerView.bottomAnchor, trailing: descriptionLabel.trailingAnchor, paddingBottom: -Constants.padding.innerCell, height: 22)
        
        bottomStackView.alignment = .bottom
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        containerView.layer.cornerRadius = Constants.cellCornerRadius
        containerView.setDefaultShadow()
    }
    
}
