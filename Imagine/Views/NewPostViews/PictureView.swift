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
    private var collectionViewWidthConstraint: NSLayoutConstraint?
    
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
    
    //MARK:- View Functions
    override func layoutSubviews() {
        removePictureButton.cornerRadius = removePictureButton.frame.height/2
    }
    
    //MARK:- Show Picture
    func showPicture(image: UIImage?) {
        
        guard let widthConstraint = collectionViewWidthConstraint else {
            return
        }
        
        //Calculate the perfect fit, so that whenever possible, the whole image will be displayed
        if let image = image {
            let imageHeight = image.size.height
            let imageWidth = image.size.width
            
            let pictureViewHeight = Constants.NewPostConstants.increasedPictureViewHeightConstraint
            
            let ratio = imageWidth / imageHeight
            let height = pictureViewHeight-20  // 10+10 from top and bottom space
            let newWidth = height * ratio
            
            widthConstraint.constant = newWidth
        }
        
        previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
            self.removePictureButton.alpha = 1
            self.removePictureButton.isEnabled = true
        }
    }
    
    //MARK:- Set Up View
    
    private func setPictureViewUI() {
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
            cameraButton.backgroundColor = .ios12secondarySystemBackground
            folderButton.backgroundColor = .ios12secondarySystemBackground
        }
        
        addSubview(folderButton)
        folderButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        folderButton.leadingAnchor.constraint(equalTo: cameraButton.trailingAnchor, constant: 15).isActive = true
        folderButton.widthAnchor.constraint(equalToConstant: 34).isActive = true
        folderButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        folderButton.layer.cornerRadius = 17
        
        addSubview(previewCollectionView)
        previewCollectionView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        previewCollectionView.leadingAnchor.constraint(greaterThanOrEqualTo: folderButton.trailingAnchor, constant: 25).isActive = true  //greaterThanOrE
        previewCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        collectionViewWidthConstraint = previewCollectionView.widthAnchor.constraint(equalToConstant: 200)
        collectionViewWidthConstraint!.isActive = true
        collectionViewWidthConstraint!.priority = UILayoutPriority(750)
        previewCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
        
        addSubview(removePictureButton)
        removePictureButton.topAnchor.constraint(equalTo: previewCollectionView.topAnchor, constant: -8).isActive = true
        removePictureButton.trailingAnchor.constraint(equalTo: previewCollectionView.trailingAnchor, constant: 8).isActive = true
        removePictureButton.widthAnchor.constraint(equalToConstant: 22).isActive = true
        removePictureButton.heightAnchor.constraint(equalToConstant: 22).isActive = true
        
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
        button.tintColor = .darkRed
        button.imageEdgeInsets = UIEdgeInsets(top: 2,left: 2,bottom: 2,right: 2)
        if #available(iOS 13.0, *) {
            button.backgroundColor = .systemBackground
        } else {
            button.backgroundColor = .white
        }
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
