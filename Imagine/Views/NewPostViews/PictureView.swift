//
//  PictureView.swift
//  Imagine
//
//  Created by Malte Schoppe on 28.02.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class PictureView: UIView {
    
    //MARK:- Variables
    var newPostVC: NewPostViewController?
    
    //MARK:- Initialization
    init(newPostVC: NewPostViewController) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        self.newPostVC = newPostVC
        
        translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        } else {
            backgroundColor = .white
        }
        
        setPictureViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- Set Up View
    
    func setPictureViewUI() {
        addSubview(pictureLabel)
        pictureLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        pictureLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        pictureLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        pictureLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(cameraButton)
        cameraButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        cameraButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15).isActive = true
        cameraButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        cameraButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        cameraButton.layer.cornerRadius = 17
        if #available(iOS 13.0, *) {
            cameraButton.backgroundColor = .secondarySystemBackground
            folderButton.backgroundColor = .secondarySystemBackground
        } else {
            // Fallback on earlier versions
        }
        
        addSubview(folderButton)
        folderButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        folderButton.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 15).isActive = true
        folderButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        folderButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        folderButton.layer.cornerRadius = 17
        
        addSubview(previewCollectionView)
        previewCollectionView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        previewCollectionView.leadingAnchor.constraint(equalTo: folderButton.trailingAnchor, constant: 25).isActive = true
        previewCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        previewCollectionView.widthAnchor.constraint(equalToConstant: 125).isActive = true
        previewCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        
        addSubview(removePictureButton)
        removePictureButton.topAnchor.constraint(equalTo: previewCollectionView.topAnchor, constant: -5).isActive = true
        removePictureButton.trailingAnchor.constraint(equalTo: previewCollectionView.trailingAnchor, constant: 5).isActive = true
        removePictureButton.widthAnchor.constraint(equalToConstant: 18).isActive = true
        removePictureButton.heightAnchor.constraint(equalToConstant: 18).isActive = true
        
    }
    
    //MARK:- UI Init
    
    let pictureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("pictureLabelText", comment: "picture:")
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        label.alpha = 0
        
        return label
    }()
    
    let cameraButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "camera"), for: .normal)
        button.addTarget(self, action: #selector(camTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.alpha = 0
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        button.tintColor = .imagineColor
        
        return button
    }()
    
    let folderButton :DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "folder"), for: .normal)
        button.addTarget(self, action: #selector(camRollTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        button.alpha = 0
        if #available(iOS 13.0, *) {
            button.tintColor = .label
        } else {
            button.tintColor = .black
        }
        button.tintColor = .imagineColor
        
        return button
    }()
    
    let removePictureButton :DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "DismissTemplate"), for: .normal)
        button.alpha = 0
        button.tintColor = .systemRed
        button.backgroundColor = .white
        button.cornerRadius = 9
        button.addTarget(self, action: #selector(removePictureTapped), for: .touchUpInside)
        
        return button
    }()
    
    
    
    let previewCollectionView: UICollectionView = {
       let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
        collectView.translatesAutoresizingMaskIntoConstraints = false
        collectView.allowsSelection = true  //Pictures clickable
        collectView.layer.cornerRadius = 8
        collectView.isPagingEnabled = true
        if #available(iOS 13.0, *) {
            collectView.backgroundColor = .systemBackground
        } else {
            collectView.backgroundColor = .white
        }
        
        return collectView
    }()
    
    //MARK:- Actions
    
    @objc func camTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.camTapped()
    }
    
    @objc func camRollTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.camRollTapped()
    }
    
    @objc func removePictureTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.removePictureTapped()
    }
}
