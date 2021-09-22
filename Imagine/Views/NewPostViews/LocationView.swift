//
//  LocationView.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class LocationView: UIView {
    
    //MARK:- Variables
    var newPostVC: NewPostViewController?
    let infoButtonSize = Constants.NewPostConstants.infoButtonSize
    let labelHeight = Constants.NewPostConstants.labelHeight
    
    //MARK:- Initializer
    init(newPostVC: NewPostViewController) {
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize.zero))
        
        self.newPostVC = newPostVC
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        
        setUpLocationViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Set Up View
    
    func setUpLocationViewUI() {
        
        //LocationView
        addSubview(locationDescriptionLabel)
        locationDescriptionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        locationDescriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        locationDescriptionLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = true
        
        addSubview(linkedLocationImageView)
        linkedLocationImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: (labelHeight/2)+2).isActive = true
        linkedLocationImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14).isActive = true
        linkedLocationImageView.widthAnchor.constraint(equalToConstant: 17).isActive = true
        linkedLocationImageView.heightAnchor.constraint(equalToConstant: 17).isActive = true
        
        addSubview(choosenLocationLabel)
        choosenLocationLabel.centerYAnchor.constraint(equalTo: linkedLocationImageView.centerYAnchor).isActive = true
        choosenLocationLabel.leadingAnchor.constraint(equalTo: locationDescriptionLabel.trailingAnchor, constant: 10).isActive = true
        
        addSubview(chooseLocationButton)
        chooseLocationButton.leadingAnchor.constraint(equalTo: choosenLocationLabel.trailingAnchor, constant: 20).isActive = true
        chooseLocationButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        chooseLocationButton.centerYAnchor.constraint(equalTo: choosenLocationLabel.centerYAnchor).isActive = true
        chooseLocationButton.heightAnchor.constraint(equalToConstant: infoButtonSize-3).isActive = true
        chooseLocationButton.widthAnchor.constraint(equalToConstant: infoButtonSize-3).isActive = true
        
    }
    
    //MARK:- UI Init
    
    let locationDescriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("location_label_text", comment: "location:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        
        return label
    }()
    
    let choosenLocationLabel : UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        label.textAlignment = .center
        
        return label
    }()
    
    let chooseLocationButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mapIcon"), for: .normal)
        button.addTarget(self, action: #selector(chooseLocationButtonTapped), for: .touchUpInside)
        button.tintColor = .imagineColor
        
        return button
    }()
    
    let linkedLocationImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "locationCircle")
        imageView.tintColor = .secondaryLabel
        
        return imageView
    }()
    
    //MARK:- Actions
    
    @objc func chooseLocationButtonTapped() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.chooseLocationButtonTapped()
    }
}
