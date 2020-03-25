//
//  CommunityCollectionCell.swift
//  Imagine
//
//  Created by Malte Schoppe on 09.03.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit

enum CommunityCellType {
    case first
    case second
}

enum CommunityCellButtonType {
    case vision
    case communityChat
    case moreInfo
    case proposals
    case help
    case settings
}

protocol CommunityCollectionCellDelegate {
    func buttonTapped(button: CommunityCellButtonType)
}

class CommunityCollectionCell: UICollectionViewCell {
    
    var cellType: CommunityCellType = .first
    
    var firstButtonWidthConstraint: NSLayoutConstraint?
    var secondButtonHeightConstraint: NSLayoutConstraint?
    
    var delegate: CommunityCollectionCellDelegate?
    
    override func awakeFromNib() {
        clipsToBounds = true
        backgroundColor = .green
        
    }
    
    override func prepareForReuse() {
        firstStackView.removeFromSuperview()
        firstButton.removeFromSuperview()
        firstButton.setImage(nil, for: .normal)
        firstImageView.removeFromSuperview()
        secondImageView.removeFromSuperview()
        thirdButton.removeFromSuperview()
        
        firstImageView.image = nil
        secondImageView.image = nil
        
        if let width = firstButtonWidthConstraint {
            width.isActive = false
        }
        if let height = secondButtonHeightConstraint {
            height.isActive = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        firstButton.addTarget(self, action: #selector(firstButtonTapped), for: .touchUpInside)
        secondButton.addTarget(self, action: #selector(secondButtonTapped), for: .touchUpInside)
        thirdButton.addTarget(self, action: #selector(thirdButtonTapped), for: .touchUpInside)
        
        
        switch cellType {
        case .first:
            addSubview(firstStackView)
            
            firstStackView.distribution = .fillEqually

            firstStackView.addArrangedSubview(firstButton)
            firstButton.setTitle("Vision", for: .normal)
            
            firstStackView.addSubview(firstImageView)
            firstImageView.topAnchor.constraint(equalTo: firstButton.topAnchor, constant: 14).isActive = true
            firstImageView.trailingAnchor.constraint(equalTo: firstButton.trailingAnchor, constant: -12).isActive = true
            firstImageView.heightAnchor.constraint(equalToConstant: 17).isActive = true
            firstImageView.widthAnchor.constraint(equalToConstant: 34).isActive = true
            firstImageView.image = UIImage(named: "visionEye")

            secondStackView.addArrangedSubview(secondButton)
            secondButton.backgroundColor = .imagineColor
            secondButton.setTitleColor(.white, for: .normal)
            secondButton.setTitle("Community Chat", for: .normal)
            secondButtonHeightConstraint = secondButton.heightAnchor.constraint(equalToConstant: 40)
            secondButtonHeightConstraint!.isActive = true
            
            secondStackView.addArrangedSubview(thirdButton)
            thirdButton.setTitle("Mehr Infos", for: .normal)
            secondStackView.addSubview(secondImageView)
            secondImageView.topAnchor.constraint(equalTo: thirdButton.topAnchor, constant: 13).isActive = true
            secondImageView.trailingAnchor.constraint(equalTo: thirdButton.trailingAnchor, constant: -13).isActive = true
            secondImageView.heightAnchor.constraint(equalToConstant: 21).isActive = true
            secondImageView.widthAnchor.constraint(equalToConstant: 21).isActive = true
            secondImageView.image = UIImage(named: "infoIcon")

            firstStackView.addArrangedSubview(secondStackView)

            firstStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            firstStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            firstStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
            firstStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

            
            
        case .second:
            addSubview(firstStackView)

            firstStackView.distribution = .fill

            
            thirdButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
            thirdButton.setTitle("Mithilfe", for: .normal)
            thirdButton.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 16)
            thirdButton.backgroundColor = .imagineColor
            thirdButton.setTitleColor(.white, for: .normal)
            thirdButton.layer.cornerRadius = 4
            
            secondStackView.addArrangedSubview(firstButton)
            secondStackView.addArrangedSubview(thirdButton)
            firstStackView.addArrangedSubview(secondStackView)
            firstButton.setImage(UIImage(named: "settings"), for: .normal)
            if #available(iOS 13.0, *) {
                firstButton.imageView?.tintColor = .label
            } else {
                firstButton.imageView?.tintColor = .black
            }
//            firstButton.setImage(UIImage(named: "helpButton"), for: .normal)
//            firstButton.setTitle("Hilfe", for: .normal)

            firstStackView.addArrangedSubview(secondButton)
            secondButton.setTitle("Vorschläge", for: .normal)
            secondButton.setTitleColor(.imagineColor, for: .normal)
            if #available(iOS 13.0, *) {
                secondButton.backgroundColor = .quaternarySystemFill
            } else {
                secondButton.backgroundColor = .ios12secondarySystemBackground
            }
            
            firstStackView.addSubview(firstImageView)
            firstImageView.topAnchor.constraint(equalTo: secondButton.topAnchor, constant: 10).isActive = true
            firstImageView.trailingAnchor.constraint(equalTo: secondButton.trailingAnchor, constant: -10).isActive = true
            firstImageView.heightAnchor.constraint(equalToConstant: 37).isActive = true
            firstImageView.widthAnchor.constraint(equalToConstant: 43).isActive = true
            firstImageView.image = UIImage(named: "lightBulb")

            firstStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            firstStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            firstStackView.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
            firstStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

            self.firstButtonWidthConstraint = firstButton.widthAnchor.constraint(equalToConstant: 75)
            self.firstButtonWidthConstraint!.isActive = true
        }
    }
    
    @objc func firstButtonTapped() {
        if cellType == .first {
            delegate?.buttonTapped(button: .vision)
        } else {
            delegate?.buttonTapped(button: .settings)
        }
    }
    
    @objc func secondButtonTapped() {
        if cellType == .first {
            delegate?.buttonTapped(button: .communityChat)
        } else {
            delegate?.buttonTapped(button: .proposals)
        }
    }
    
    @objc func thirdButtonTapped() {
        if cellType == .first {
            delegate?.buttonTapped(button: .moreInfo)
        } else {
            delegate?.buttonTapped(button: .help)
        }
    }
    
    let firstStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 20
        
        return stack
    }()
    
    let secondStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fill
        stack.spacing = 20
        
        
        return stack
    }()
    
    let firstButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 20)
        button.setTitleColor(.imagineColor, for: .normal)
        button.addTarget(self, action: #selector(firstButtonTapped), for: .touchUpInside)
        
        if #available(iOS 13.0, *) {
            button.backgroundColor = .quaternarySystemFill
        } else {
            button.backgroundColor = .ios12secondarySystemBackground
        }
        
        return button
    }()
    
    let secondButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.setTitleColor(.imagineColor, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 20)
        
        if #available(iOS 13.0, *) {
            button.backgroundColor = .quaternarySystemFill
        } else {
            button.backgroundColor = .ios12secondarySystemBackground
        }
        
        return button
    }()
    
    let thirdButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.setTitleColor(.imagineColor, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 20)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        
        
        if #available(iOS 13.0, *) {
            button.backgroundColor = .quaternarySystemFill
        } else {
            button.backgroundColor = .ios12secondarySystemBackground
        }
        
        return button
    }()
    
    let firstImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    let secondImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
}
