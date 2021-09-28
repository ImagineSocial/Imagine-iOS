//
//  OptionView.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseAuth

class OptionView: UIView {
    
    //MARK:- Variables
    private var newPostVC: NewPostViewController?
    
    private let infoButtonSize = Constants.NewPostConstants.infoButtonSize
    private let defaultOptionViewHeight = Constants.NewPostConstants.defaultOptionViewHeight
    
    private let defaultSynonymText = "Enter synonym..."
    private let anonymousName = Constants.strings.anonymPosterName
    
    private var postAnonymous = false
    private var anonymousSynonym: String?
    
    private var username: String?
    
    //Constraints
    private var leadingPreviewNameLabelToImageView: NSLayoutConstraint?
    private var leadingPreviewNameLabelToSuperview: NSLayoutConstraint?
    
    
    //MARK:- Initialization
    init(newPostVC: NewPostViewController) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        self.newPostVC = newPostVC
        
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        
        setUpOptionViewUI()
        synonymTextView.delegate = self
        setUpUser()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- View Functions
    override func layoutSubviews() {
        previewImageView.layer.cornerRadius = previewImageView.frame.width/2
        previewView.layer.cornerRadius = 10
    }
    
    //MARK:- Get Settings
    /// Get the options, that were selected to upload them
    public func getSettings() -> (postAnonymous: Bool, hideProfile: Bool, synonymString: String?) {
        
        return (postAnonymous, hideProfilePictureSwitch.isOn, anonymousSynonym)
    }
    
    //MARK:- Set Up User
    func setUpUser() {
        
        //SetUp Preview Date Label
        let date = Date()
        let feedString = date.formatForFeed()
        previewDateLabel.text = feedString
        
        // Set Up User
        if let user = Auth.auth().currentUser {
            
            //Get only first name to accurately show how it will be displayed
            User(userID: user.uid).getUsername() { (username) in
                if let name = username {
                    self.username = name
                    self.previewNameLabel.text = name
                }
            }
            
            //Show Profile Picture
            if let url = user.photoURL {
                previewImageView.sd_setImage(with: url, completed: nil)
            }
        } else {
            previewNameLabel.text = "Mr. not logged in"
            previewImageView.image = UIImage(named: "default-user")
        }
    }
    
    //MARK:- Set Up Options UI
    func setUpOptionViewUI() {
        
        guard let newPostVC = newPostVC else {
            return
        }
        
        addSubview(optionButton)
        optionButton.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        optionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        optionButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        //Meme Mode Button
        addSubview(memeModeButton)
        memeModeButton.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor).isActive = true
        memeModeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        memeModeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        //Preview View
        previewView.addSubview(previewImageView)
        previewView.addSubview(previewNameLabel)
        previewView.addSubview(previewDateLabel)
        addSubview(previewView)
        
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

        //OptionStackView
        optionStackView.addArrangedSubview(hideProfilePictureView)
        optionStackView.addArrangedSubview(postAnonymousView)
        
        addSubview(optionStackView)
        optionStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        optionStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        optionStackView.topAnchor.constraint(equalTo: optionButton.bottomAnchor, constant: 3).isActive = true
        optionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        newPostVC.stackViewHeight = optionStackView.heightAnchor.constraint(equalToConstant: 0)
        newPostVC.stackViewHeight!.isActive = true
        
        setHideProfilePictureViewUI()
        setPostAnonymousViewUI()
    }
    
    func setHideProfilePictureViewUI() {
        hideProfilePictureView.addSubview(hideProfilePictureSwitch)
        hideProfilePictureSwitch.centerYAnchor.constraint(equalTo: hideProfilePictureView.centerYAnchor).isActive = true
        hideProfilePictureSwitch.leadingAnchor.constraint(equalTo: hideProfilePictureView.leadingAnchor, constant: 10).isActive = true
        
        hideProfilePictureView.addSubview(hideProfilePictureLabel)
        hideProfilePictureLabel.centerXAnchor.constraint(equalTo: hideProfilePictureView.centerXAnchor).isActive = true
        hideProfilePictureLabel.leadingAnchor.constraint(equalTo: hideProfilePictureView.leadingAnchor, constant: 100).isActive = true
        hideProfilePictureLabel.centerYAnchor.constraint(equalTo: hideProfilePictureView.centerYAnchor).isActive = true
    }
    
    func setPostAnonymousViewUI() {
        
        postAnonymousView.addSubview(anonymousButton)
        anonymousButton.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        anonymousButton.leadingAnchor.constraint(equalTo: postAnonymousView.leadingAnchor, constant: 18).isActive = true
        anonymousButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        anonymousButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        postAnonymousView.addSubview(synonymTextView)
        synonymTextView.leadingAnchor.constraint(equalTo: postAnonymousView.leadingAnchor, constant: 95).isActive = true
        synonymTextView.topAnchor.constraint(equalTo: postAnonymousView.topAnchor, constant: 5).isActive = true
        synonymTextView.bottomAnchor.constraint(equalTo: postAnonymousView.bottomAnchor, constant: -5).isActive = true
        synonymTextView.text = defaultSynonymText
        
        
        postAnonymousView.addSubview(postAnonymousButton)
        postAnonymousButton.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousButton.leadingAnchor.constraint(equalTo: synonymTextView.trailingAnchor, constant: 10).isActive = true
        postAnonymousButton.trailingAnchor.constraint(equalTo: postAnonymousView.trailingAnchor, constant: -10).isActive = true
        postAnonymousButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        postAnonymousButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
    }
    
    //MARK:- Change UI
    private func changeAnonymousStatus() {
        if postAnonymous {
            postAnonymous = false
            
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
            
            postAnonymous = true
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
    
    //MARK:- Actions
    
    @objc func optionButtonTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.optionButtonTapped()
    }
    
    @objc func memeModeTapped() {
        guard let newPostVC = newPostVC else { return }
        newPostVC.memeModeTapped()
    }
    
    //MARK: Post Anonymous
    
    @objc func anonymousButtonTapped() {
        changeAnonymousStatus()
    }
    
    @objc func postAnonymousInfoButtonPressed() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.postAnonymousButtonPressed()
    }
    
    //MARK: Hide Picture
    
    @objc func hideProfilePictureSwitchChanged() {
        if hideProfilePictureSwitch.isOn {
            hideProfilePicture()
        } else {
            showProfilePicture()
        }
    }
    
    //MARK:- UI Init
    
    //MARK: Options
    
    let optionButton: DesignableButton = {  // little Burger Menu
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .imagineColor
        button.setImage(UIImage(named: "menu"), for: .normal)
        button.addTarget(self, action: #selector(optionButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    let optionStackView: UIStackView = {
       let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alpha = 0
        stack.isHidden = true
        stack.distribution = .fillEqually
        
        return stack
    }()
    
    //MARK: - Meme Mode Button UI
    
    let memeModeButton: DesignableButton = {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let tronColor = UIColor(red: 0.05, green: 0.97, blue: 0.97, alpha: 1.00)
        
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: UIColor.label]))
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: tronColor]))
        
        button.setTitleColor(tronColor, for: .normal)
        button.setAttributedTitle(text, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(memeModeTapped), for: .touchUpInside)
        
        return button
    }()
    
    //MARK:- Hide PofilePicture
    let hideProfilePictureView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        
        return view
    }()
    
    let hideProfilePictureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Hide profile picture"
        label.textColor = .secondaryLabel
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        
        return label
    }()
    
    let hideProfilePictureSwitch: UISwitch = {
        let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.addTarget(self, action: #selector(hideProfilePictureSwitchChanged), for: .valueChanged)
        switcher.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        
        return switcher
    }()
    
    //MARK:- Anonymous
    
    let postAnonymousView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        
        return view
    }()
    
    let anonymousButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mask"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(anonymousButtonTapped), for: .touchUpInside)
        
        return button
    }()
    
    let synonymTextView: UITextView = {
       let textField = UITextView()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        textField.textColor = .secondaryLabel
        textField.isScrollEnabled = false
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        
        return textField
    }()
    
    let postAnonymousButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(postAnonymousInfoButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    //MARK:- Preview UI
    let previewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "default-user")
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layoutIfNeeded()
        
        return imageView
    }()
    
    let previewDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Light", size: 8)
        label.textColor = .secondaryLabel
        
        return label
    }()
    
    let previewNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 11)
        label.text = "Malte"
        
        return label
    }()
    
}

//MARK:- TextViewDelegate
extension OptionView: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if !postAnonymous {
            //Set Anonymous posting UI active
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
            anonymousSynonym = nil
        } else {
            previewNameLabel.text = textView.text
            anonymousSynonym = textView.text
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        //Set the default text if nothing is entered
        if textView.text == "" {
            textView.text = self.defaultSynonymText
            previewNameLabel.text = anonymousName
            anonymousSynonym = nil
            
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
