//
//  NewPostLocationCell.swift
//  Imagine
//
//  Created by Don Malte on 09.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostLocationCell: NewPostBaseCell {
    
    //MARK: - Variables
    
    static let identifier = "NewPostLocationCell"
    
    let labelHeight = Constants.NewPostConstants.labelHeight
    
    // MARK: - Elements
    
    let locationDescriptionLabel = BaseLabel(text: Strings.newPostLocationLabel, font: titleLabelFont)
    let choosenLocationLabel = BaseLabel(font: .standard(with: .medium, size: 14), textAlignment: .right)
    let chooseLocationButton = BaseButtonWithImage(image: Icons.map, tintColor: .imagineColor)
    let linkedLocationImageView = BaseImageView(image: Icons.location, tintColor: .secondaryLabel)
    let cancelLinkedLocationButton = BaseButtonWithImage(image: Icons.dismiss, tintColor: .darkRed)
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Set Up View
    
    override func setupConstraints() {
        super.setupConstraints()
        
        addSubview(locationDescriptionLabel)
        addSubview(linkedLocationImageView)
        addSubview(choosenLocationLabel)
        addSubview(chooseLocationButton)
        addSubview(cancelLinkedLocationButton)
        
        NSLayoutConstraint.activate([
            locationDescriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            locationDescriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            locationDescriptionLabel.heightAnchor.constraint(equalToConstant: labelHeight),
            
            linkedLocationImageView.topAnchor.constraint(equalTo: locationDescriptionLabel.bottomAnchor, constant: 10),
            linkedLocationImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            linkedLocationImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            linkedLocationImageView.widthAnchor.constraint(equalToConstant: 17),
            linkedLocationImageView.heightAnchor.constraint(equalToConstant: 17),
            
            choosenLocationLabel.centerYAnchor.constraint(equalTo: linkedLocationImageView.centerYAnchor),
            choosenLocationLabel.leadingAnchor.constraint(equalTo: linkedLocationImageView.trailingAnchor, constant: 10),
            
            cancelLinkedLocationButton.leadingAnchor.constraint(equalTo: choosenLocationLabel.trailingAnchor, constant: 10),
            cancelLinkedLocationButton.centerYAnchor.constraint(equalTo: linkedLocationImageView.centerYAnchor),
            cancelLinkedLocationButton.widthAnchor.constraint(equalToConstant: infoButtonSize),
            cancelLinkedLocationButton.heightAnchor.constraint(equalToConstant: infoButtonSize),
            
            chooseLocationButton.leadingAnchor.constraint(equalTo: cancelLinkedLocationButton.trailingAnchor, constant: 10),
            chooseLocationButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            chooseLocationButton.centerYAnchor.constraint(equalTo: linkedLocationImageView.centerYAnchor),
            chooseLocationButton.heightAnchor.constraint(equalToConstant: infoButtonSize),
            chooseLocationButton.widthAnchor.constraint(equalToConstant: infoButtonSize)
        ])
        
        chooseLocationButton.addTarget(self, action: #selector(chooseLocationButtonTapped), for: .touchUpInside)
        cancelLinkedLocationButton.addTarget(self, action: #selector(cancelLocationButtonTapped), for: .touchUpInside)
        cancelLinkedLocationButton.isHidden = true
        cancelLinkedLocationButton.clipsToBounds = true
    }
    
    override func resetInput() {
        super.resetInput()
        
        setLocation(location: nil)
    }
    
    func setLocation(location: Location?) {
        choosenLocationLabel.text = location?.title ?? ""
        cancelLinkedLocationButton.isHidden = location == nil ? true : false
    }
    
    //MARK: - Actions
    
    @objc func chooseLocationButtonTapped() {
        delegate?.buttonTapped(newPostButton: .location)
    }
    
    @objc func cancelLocationButtonTapped() {
        delegate?.buttonTapped(newPostButton: .cancelLocation)
    }
}
