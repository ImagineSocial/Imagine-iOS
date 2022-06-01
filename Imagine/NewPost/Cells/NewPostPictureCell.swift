//
//  NewPostPictureCell.swift
//  Imagine
//
//  Created by Don Malte on 08.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

class NewPostPictureCell: NewPostBaseCell {

    static let identifier = "NewPostPictureCell"
    
    private var collectionViewWidthConstraint: NSLayoutConstraint?
    private var collectionViewHeightConstraint: NSLayoutConstraint?

    var previewPictures = [UIImage]()
        
    // MARK: - Elements
    
    let pictureLabel = BaseLabel(text: Strings.newPostPictureLabel, font: titleLabelFont)
    let cameraButton = BaseButtonWithImage(image: Icons.camera, tintColor: .imagineColor)
    let folderButton = BaseButtonWithImage(image: Icons.folder, tintColor: .imagineColor)
    let removePictureButton = BaseButtonWithImage(image: Icons.dismiss, tintColor: .secondaryLabel)
    
    let previewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectView.translatesAutoresizingMaskIntoConstraints = false
        
        collectView.allowsSelection = true
        collectView.layer.cornerRadius = 8
        collectView.isPagingEnabled = true
        collectView.backgroundColor = .systemBackground
        
        return collectView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        setupPreviewCollectionView()
        
        backgroundColor = .systemBackground        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        removePictureButton.cornerRadius = removePictureButton.frame.height/2
        
        //resize the layout
        previewCollectionView.reloadData()
    }
    
    //MARK: - Show Picture
    
    func showPicture(image: UIImage?) {
        if let image = image {
            previewPictures.append(image)
        }
        
        guard let widthConstraint = collectionViewWidthConstraint else {
            return
        }
        
        //Calculate the perfect fit, so that whenever possible, the whole image will be displayed
        if let image = image {
            let imageHeight = image.size.height
            let imageWidth = image.size.width
            
            let pictureViewHeight = Constants.NewPostConstants.increasedPictureViewHeightConstraint
            
            let ratio = imageWidth / imageHeight
            let height = pictureViewHeight - 20  // 10+10 from top and bottom space
            let newWidth = height * ratio
            
            widthConstraint.constant = newWidth
            if !widthConstraint.isActive {
                widthConstraint.isActive = true
            }
        } else {
            //multiPicture
            widthConstraint.isActive = false
        }
        previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
            self.removePictureButton.alpha = 1
            self.removePictureButton.isEnabled = true
        }
    }
    
    //MARK: - Set Up View
    
    override func setupConstraints() {
        super.setupConstraints()
        
        addSubview(pictureLabel)
        addSubview(cameraButton)
        addSubview(folderButton)
        addSubview(previewCollectionView)
        addSubview(removePictureButton)
                
        pictureLabel.constrain(top: topAnchor, leading: leadingAnchor, paddingTop: 5, paddingLeading: padding, width: 80, height: 20)
        
        cameraButton.constrain(leading: leadingAnchor, bottom: bottomAnchor, paddingLeading: padding, paddingBottom: -10, width: 34, height: 34)
        folderButton.constrain(leading: cameraButton.trailingAnchor, bottom: bottomAnchor, paddingLeading: padding, paddingBottom: -10, width: 34, height: 34)
        
        previewCollectionView.constrain(top: topAnchor, bottom: bottomAnchor, trailing: trailingAnchor, paddingTop: 10, paddingBottom: -10, paddingTrailing: -padding)
        previewCollectionView.leadingAnchor.constraint(greaterThanOrEqualTo: folderButton.trailingAnchor, constant: 25).isActive = true
        
        collectionViewWidthConstraint = previewCollectionView.widthAnchor.constraint(equalToConstant: 200)
        collectionViewHeightConstraint = previewCollectionView.heightAnchor.constraint(equalToConstant: 75)
        
        collectionViewHeightConstraint!.isActive = true
        collectionViewWidthConstraint!.isActive = true
        collectionViewWidthConstraint!.priority = UILayoutPriority.defaultHigh
        
        removePictureButton.constrain(top: previewCollectionView.topAnchor, trailing: previewCollectionView.trailingAnchor, paddingTop: 8, paddingTrailing: -8, width: 22, height: 22)
        
        cameraButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        folderButton.imageEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        
        removePictureButton.imageEdgeInsets = UIEdgeInsets(top: 2,left: 2,bottom: 2,right: 2)
        removePictureButton.backgroundColor = .systemBackground
        
        cameraButton.addTarget(self, action: #selector(openCamera), for: .touchUpInside)
        folderButton.addTarget(self, action: #selector(openPhotoLibrary), for: .touchUpInside)
        removePictureButton.addTarget(self, action: #selector(removePictureTapped), for: .touchUpInside)
        
        removePictureButton.alpha = 0
    }
    
    override func resetInput() {
        super.resetInput()
        
        removePictureTapped()
    }
    
    //MARK: - Actions
    
    @objc func openCamera() {
        delegate?.openImagePicker(for: .camera)
    }
    
    @objc func openPhotoLibrary() {
        delegate?.openImagePicker(for: .photoLibrary)
    }
    
    @objc func removePictureTapped() {
        
        self.previewPictures.removeAll()
        previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.1) {
            self.removePictureButton.alpha = 0
            self.removePictureButton.isEnabled = false
        }
        
        self.decreaseCollectionView()
        delegate?.removePictures()
    }
    
    private func increaseCollectionView() {
        self.collectionViewHeightConstraint?.constant = 200 
    }
    
    private func decreaseCollectionView() {
        self.collectionViewHeightConstraint?.constant = 75
    }
    
    func presentImages(images: [UIImage]) {
        increaseCollectionView()
        
        previewPictures = images
        previewCollectionView.reloadData()
        
        UIView.animate(withDuration: 0.3) {
            self.removePictureButton.alpha = 1
            self.removePictureButton.isEnabled = true
        }
    }
    
    func openImage(image: UIImage) {
        delegate?.showImage(image)
    }
}

extension NewPostPictureCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func setupPreviewCollectionView() {
        previewCollectionView.register(MultiImageCollectionCell.self, forCellWithReuseIdentifier: MultiImageCollectionCell.identifier)
        
        previewCollectionView.dataSource = self
        previewCollectionView.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        previewPictures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = previewPictures[indexPath.item]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MultiImageCollectionCell.identifier, for: indexPath) as? MultiImageCollectionCell {
            
            cell.image = image
            cell.layoutIfNeeded()
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let image = previewPictures[indexPath.item]
        
        openImage(image: image)
    }
}

