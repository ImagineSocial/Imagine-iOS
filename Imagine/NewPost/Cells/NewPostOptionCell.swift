//
//  NewPostOptionCell.swift
//  Imagine
//
//  Created by Don Malte on 09.01.22.
//  Copyright © 2022 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseAuth

//MARK: - Get Settings
/// Get the options, that were selected to upload them
class NewPostOption {
    var postAnonymous = false
    var hideProfile = false
    var synonymString: String?
}

class NewPostOptionCell: NewPostBaseCell {
    
    //MARK: - Variables
    
    static let identifier = "NewPostOptionCell"
        
    private let defaultOptionViewHeight = Constants.NewPostConstants.defaultOptionViewHeight
    
    private let defaultSynonymText = "Enter synonym..."
    private let anonymousName = Constants.strings.anonymPosterName
        
    private var username: String?
    
    private var leadingPreviewNameLabelToImageView: NSLayoutConstraint?
    private var leadingPreviewNameLabelToSuperview: NSLayoutConstraint?
    
    private var stackViewHeight: NSLayoutConstraint?
    
    var option = NewPostOption()
    
    
    // TODO: Set Options here
    
    // MARK: - Elements
    
    let optionButton = BaseButtonWithImage(image: Icons.menu, tintColor: .imagineColor)
    let hideProfilePictureView = BaseView()
    let hideProfilePictureLabel = BaseLabel(text: "Hide profile picture", textColor: .secondaryLabel, font: .standard(with: .medium, size: 14))
    let postAnonymousView = BaseView()
    let anonymousButton = BaseButtonWithImage(image: Icons.mask, tintColor: .imagineColor)
    let synonymTextView = BaseTextView(textColor: .secondaryLabel, font: .standard(with: .medium, size: 14), returnType: .done)
    let postAnonymousButton = BaseButtonWithImage(image: Icons.info)
    let previewView = BaseView()
    let previewImageView = BaseImageView(image: Icons.defaultUser)
    let previewDateLabel = BaseLabel(textColor: .secondaryLabel, font: .standard(with: .light, size: 8))
    let previewNameLabel = BaseLabel(text: "", font: .standard(size: 11))
    
    lazy var optionStackView = BaseStackView(subviews: [hideProfilePictureView, postAnonymousView], axis: .vertical, distribution: .fillEqually)
        
    let memeModeButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label]))
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: UIColor.tron]))
        
        button.setAttributedTitle(text, for: .normal)
        button.titleLabel?.font = .standard(with: .medium, size: 14)
        
        return button
    }()
    
    let hideProfilePictureSwitch: UISwitch = {
        let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        
        return switcher
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
                
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        
        synonymTextView.delegate = self
        setUpUser()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        previewImageView.layer.cornerRadius = previewImageView.frame.width/2
        previewView.layer.cornerRadius = 10
    }
    
    
    //MARK: - Set Up UI
    
    func setUpUser() {
        
        //SetUp Preview Date Label
        let date = Date()
        let feedString = date.formatForFeed()
        previewDateLabel.text = feedString
        
        // Set Up User
        if let user = Auth.auth().currentUser {
            
            //Get only first name to accurately show how it will be displayed
            User(userID: user.uid).loadUser() { user in
                guard let name = user?.name else { return }
                    
                self.username = name
                self.previewNameLabel.text = name
            }
            
            //Show Profile Picture
            if let url = user.photoURL {
                previewImageView.sd_setImage(with: url, completed: nil)
            }
        } else {
            previewNameLabel.text = "Mr. not logged in"
            previewImageView.image = Icons.defaultUser
        }
    }
    

    override func setupConstraints() {
        super.setupConstraints()
        
        setHideProfilePictureViewUI()
        setPostAnonymousViewUI()
        
        addSubview(optionButton)
        addSubview(memeModeButton)
        addSubview(previewView)
        previewView.addSubview(previewImageView)
        previewView.addSubview(previewNameLabel)
        previewView.addSubview(previewDateLabel)
        
        addSubview(optionStackView)
        
        optionButton.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        optionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding).isActive = true
        optionButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        //Meme Mode Button
        memeModeButton.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor).isActive = true
        memeModeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding).isActive = true
        memeModeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        leadingPreviewNameLabelToImageView = previewNameLabel.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: 10)
        leadingPreviewNameLabelToSuperview = previewNameLabel.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 5)
        
        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor, constant: 5),
            previewImageView.topAnchor.constraint(equalTo: previewView.topAnchor, constant: 5),
            previewImageView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor, constant: -5),
            previewImageView.widthAnchor.constraint(equalTo: previewImageView.heightAnchor, multiplier: 1),
            
            previewNameLabel.topAnchor.constraint(equalTo: previewImageView.topAnchor, constant: -1),
            leadingPreviewNameLabelToImageView!,
            previewNameLabel.trailingAnchor.constraint(greaterThanOrEqualTo: previewView.trailingAnchor, constant: -15),
            
            previewDateLabel.leadingAnchor.constraint(equalTo: previewNameLabel.leadingAnchor),
            previewDateLabel.bottomAnchor.constraint(equalTo: previewImageView.bottomAnchor),
            previewDateLabel.trailingAnchor.constraint(greaterThanOrEqualTo: previewView.trailingAnchor, constant: -15),
            
            previewView.leadingAnchor.constraint(equalTo: optionButton.trailingAnchor, constant: 15),
            previewView.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor),
            previewView.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-10),
            previewView.trailingAnchor.constraint(lessThanOrEqualTo: memeModeButton.leadingAnchor, constant: -10)
        ])
        
        optionStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        optionStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        optionStackView.topAnchor.constraint(equalTo: optionButton.bottomAnchor, constant: 3).isActive = true
        optionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        stackViewHeight = optionStackView.heightAnchor.constraint(equalToConstant: 0)
        stackViewHeight!.isActive = true
        
        optionButton.addTarget(self, action: #selector(optionButtonTapped), for: .touchUpInside)
        memeModeButton.addTarget(self, action: #selector(memeModeTapped), for: .touchUpInside)
        hideProfilePictureSwitch.addTarget(self, action: #selector(hideProfilePictureSwitchChanged), for: .valueChanged)
        anonymousButton.addTarget(self, action: #selector(anonymousButtonTapped), for: .touchUpInside)
        postAnonymousButton.addTarget(self, action: #selector(postAnonymousInfoButtonPressed), for: .touchUpInside)
        
        synonymTextView.isScrollEnabled = false
        synonymTextView.autocorrectionType = .no
    }
    
    func setHideProfilePictureViewUI() {
        hideProfilePictureView.alpha = 0
        hideProfilePictureView.addSubview(hideProfilePictureSwitch)
        hideProfilePictureView.addSubview(hideProfilePictureLabel)
        
        NSLayoutConstraint.activate([
        hideProfilePictureSwitch.centerYAnchor.constraint(equalTo: hideProfilePictureView.centerYAnchor),
        hideProfilePictureSwitch.leadingAnchor.constraint(equalTo: hideProfilePictureView.leadingAnchor, constant: 10),
        
        hideProfilePictureLabel.centerXAnchor.constraint(equalTo: hideProfilePictureView.centerXAnchor),
        hideProfilePictureLabel.leadingAnchor.constraint(equalTo: hideProfilePictureView.leadingAnchor, constant: 100),
        hideProfilePictureLabel.centerYAnchor.constraint(equalTo: hideProfilePictureView.centerYAnchor)
        ])
    }
    
    func setPostAnonymousViewUI() {
        postAnonymousView.alpha = 0
        
        postAnonymousView.addSubview(anonymousButton)
        postAnonymousView.addSubview(synonymTextView)
        postAnonymousView.addSubview(postAnonymousButton)

        NSLayoutConstraint.activate([
        anonymousButton.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor),
        anonymousButton.leadingAnchor.constraint(equalTo: postAnonymousView.leadingAnchor, constant: 18),
        anonymousButton.widthAnchor.constraint(equalToConstant: 30),
        anonymousButton.heightAnchor.constraint(equalToConstant: 20),
        
        synonymTextView.leadingAnchor.constraint(equalTo: postAnonymousView.leadingAnchor, constant: 95),
        synonymTextView.topAnchor.constraint(equalTo: postAnonymousView.topAnchor, constant: 5),
        synonymTextView.bottomAnchor.constraint(equalTo: postAnonymousView.bottomAnchor, constant: -5),
        
        postAnonymousButton.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor),
        postAnonymousButton.leadingAnchor.constraint(equalTo: synonymTextView.trailingAnchor, constant: 10),
        postAnonymousButton.trailingAnchor.constraint(equalTo: postAnonymousView.trailingAnchor, constant: -10),
        postAnonymousButton.widthAnchor.constraint(equalToConstant: infoButtonSize),
        postAnonymousButton.heightAnchor.constraint(equalToConstant: infoButtonSize)
        ])
        
        synonymTextView.text = defaultSynonymText
    }
    
    
    //MARK: - Change UI
    
    private func changeAnonymousStatus() {
        if option.postAnonymous {
            option.postAnonymous = false
            
            synonymTextView.resignFirstResponder()
            
            showProfilePicture()
            
            hideProfilePictureSwitch.setOn(false, animated: true)
            hideProfilePictureSwitch.isEnabled = true
            
            //Reset User
            if let name = self.username {
                previewNameLabel.text = name
            }
            
            //Highlight selection
            synonymTextView.textColor = .secondaryLabel
        } else {
            //Set right text for anonymous post
            if synonymTextView.text == defaultSynonymText {
                previewNameLabel.text = self.anonymousName
            } else {
                previewNameLabel.text = synonymTextView.text
            }
            
            hideProfilePicture()
            
            option.postAnonymous = true
            hideProfilePictureSwitch.setOn(true, animated: true)
            hideProfilePictureSwitch.isEnabled = false
            
            
            //Highlight selection
            synonymTextView.textColor = .label
        }
    }
    
    private func hideProfilePicture() {
        guard let leadingImageViewConstraint = leadingPreviewNameLabelToImageView,
              let leadingSuperviewConstraint = leadingPreviewNameLabelToSuperview else {
            return
        }
        
        //Set COnstraints
        leadingImageViewConstraint.isActive = false
        leadingSuperviewConstraint.isActive = true
        
        //Hightlight Selection
        hideProfilePictureLabel.textColor = .label
        previewNameLabel.font = UIFont(name: "IBMPlexSans-Medium", size: 11)
        
        //Hide Picture
        previewImageView.isHidden = true

        //Animate Changes
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    private func showProfilePicture() {
        guard let leadingImageViewConstraint = leadingPreviewNameLabelToImageView,
              let leadingSuperviewConstraint = leadingPreviewNameLabelToSuperview else {
            return
        }
        
        //Set COnstraints
        leadingSuperviewConstraint.isActive = false
        leadingImageViewConstraint.isActive = true
        
        //Highlight Selection
        hideProfilePictureLabel.textColor = .secondaryLabel
        previewNameLabel.font = UIFont(name: "IBMPlexSans", size: 11)
        
        //Animate Change
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        } completion: { (_) in
            self.previewImageView.isHidden = false
        }
    }
    
    //MARK: - Actions
    
    @objc func optionButtonTapped() {
        
        guard let constraint = stackViewHeight else { return }
        
        let open = constraint.constant != 0
        
        UIView.animate(withDuration: 0.3) {
            self.postAnonymousView.alpha = open ? 0 : 1
            self.hideProfilePictureView.alpha = open ? 0 : 1
        }
        
        constraint.constant = open ? 0 : 100
        delegate?.buttonTapped(newPostButton: .option)
    }
    
    @objc func memeModeTapped() {
        delegate?.buttonTapped(newPostButton: .meme)
    }
    
    // MARK: Post Anonymous
    
    @objc func anonymousButtonTapped() {
        changeAnonymousStatus()
    }
    
    @objc func postAnonymousInfoButtonPressed() {
        changeAnonymousStatus()
    }
    
    // MARK: Hide Picture
    
    @objc func hideProfilePictureSwitchChanged() {
        if hideProfilePictureSwitch.isOn {
            hideProfilePicture()
        } else {
            showProfilePicture()
        }
    }
}

//MARK: - TextViewDelegate

extension NewPostOptionCell: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if !option.postAnonymous {
            // Set Anonymous posting UI active
            changeAnonymousStatus()
        }
        
        //Delete the placeholder when the user enters data
        if textView.text == self.defaultSynonymText {
            previewNameLabel.text = anonymousName
            
            textView.text = ""
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {

        if textView.text == "" {
            previewNameLabel.text = self.anonymousName
            option.synonymString = nil
        } else {
            previewNameLabel.text = textView.text
            option.synonymString = textView.text
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        //Set the default text if nothing is entered
        if textView.text == "" {
            textView.text = self.defaultSynonymText
            previewNameLabel.text = anonymousName
            option.synonymString = nil
            
            textView.textColor = .secondaryLabel
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {

        if textView == synonymTextView {  // No lineBreaks in titleTextView
            if text.rangeOfCharacter(from: CharacterSet.whitespaces) != nil {
                return false
            } else if text.rangeOfCharacter(from: CharacterSet.newlines) != nil {
                textView.resignFirstResponder()
            }
        }

        return textView.text.count + (text.count - range.length) <= 30
    }
}
