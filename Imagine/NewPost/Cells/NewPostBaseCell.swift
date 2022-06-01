//
//  NewPostBaseCell.swift
//  Imagine
//
//  Created by Don Malte on 12.02.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit

protocol NewPostCollectionDelegate: class {
    func removePictures()
    func buttonTapped(newPostButton: NewPostButton)
    func segmentControlChanged(to value: Int)
    func showImage(_ image: UIImage?)
    func textChanged(for type: NewPostTextType, text: String?)
    func openImagePicker(for type: UIImagePickerController.SourceType)
}

class NewPostBaseCell: UICollectionViewCell {
        
    // MARK: - Variables
    
    weak var delegate: NewPostCollectionDelegate?
    
    let padding: CGFloat = 16
    let infoButtonSize = Constants.NewPostConstants.infoButtonSize
    
    static let titleLabelFont = UIFont.standard(with: .medium, size: 16)
    
    // MARK: - Elements
    
    let containerView = BaseView()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupConstraints() {
        addSubview(containerView)
        
        containerView.fillSuperview()
    }
    
    func resetInput() {
        
    }
    
    var maxWidth: CGFloat? {
        didSet {
            guard let maxWidth = maxWidth else {
                return
            }
            
            containerView.widthAnchor.constraint(equalToConstant: maxWidth).isActive = true
        }
    }
}
