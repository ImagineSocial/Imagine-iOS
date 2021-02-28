//
//  LinkView.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class LinkView: UIView {
    
    //MARK:- Initialization
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }
        
        setLinkViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- UI Init
    
    let linkLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Link:"
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let linkTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .none
        textField.placeholder = "https://..."
        textField.alpha = 0
        
        return textField
    }()
    
    let youTubeImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "YouTubeButtonIcon")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let GIFImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "GIFIcon")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let songWhipImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "MusicIcon")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let internetImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "translate")
        imageView.contentMode = .scaleAspectFill
        if #available(iOS 13.0, *) {
            imageView.tintColor = .secondaryLabel
        } else {
            imageView.tintColor = .black
        }
        imageView.alpha = 0.4
        
        return imageView
    }()
    
    let webImageViewStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.clipsToBounds = true
        stackView.alpha = 0
        
        return stackView
    }()
    
    //MARK:- Set Up View
    func setLinkViewUI() {   // have to set descriptionview topanchor
        addSubview(linkLabel)
        linkLabel.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        linkLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        linkLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        webImageViewStackView.addArrangedSubview(internetImageView)
        webImageViewStackView.addArrangedSubview(youTubeImageView)
        webImageViewStackView.addArrangedSubview(GIFImageView)
        webImageViewStackView.addArrangedSubview(songWhipImageView)
        
        internetImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        internetImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        youTubeImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        youTubeImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        GIFImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        GIFImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        songWhipImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        songWhipImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        
        addSubview(webImageViewStackView)
        webImageViewStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        webImageViewStackView.centerYAnchor.constraint(equalTo: linkLabel.centerYAnchor).isActive = true
        webImageViewStackView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        webImageViewStackView.widthAnchor.constraint(equalToConstant: 110).isActive = true
        
        addSubview(linkTextField)
        
        linkTextField.topAnchor.constraint(equalTo: linkLabel.bottomAnchor, constant: 10).isActive = true
        linkTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        linkTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -35).isActive = true
        linkTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }
    
}
