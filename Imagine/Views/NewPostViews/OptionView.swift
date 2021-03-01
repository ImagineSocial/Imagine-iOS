//
//  OptionView.swift
//  Imagine
//
//  Created by Malte Schoppe on 01.03.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit

class OptionView: UIView {
    
    //MARK:- Variables
    var newPostVC: NewPostViewController?
    
    let infoButtonSize = Constants.NewPostConstants.infoButtonSize
    let defaultOptionViewHeight = Constants.NewPostConstants.defaultOptionViewHeight
    
    
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
        
        setUpOptionViewUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        addSubview(anonymousImageView)
        anonymousImageView.leadingAnchor.constraint(equalTo: optionButton.trailingAnchor, constant: 20).isActive = true
        anonymousImageView.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor).isActive = true
        anonymousImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        anonymousImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        addSubview(anonymousNameLabel)
        anonymousNameLabel.leadingAnchor.constraint(equalTo: anonymousImageView.trailingAnchor, constant: 5).isActive = true
        anonymousNameLabel.centerYAnchor.constraint(equalTo: anonymousImageView.centerYAnchor).isActive = true
        anonymousNameLabel.heightAnchor.constraint(equalToConstant: defaultOptionViewHeight-10).isActive = true
        
        optionStackView.addArrangedSubview(markPostView)
        optionStackView.addArrangedSubview(postAnonymousView)
        
        addSubview(optionStackView)
        optionStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        optionStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        optionStackView.topAnchor.constraint(equalTo: optionButton.bottomAnchor, constant: 3).isActive = true
        optionStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
        newPostVC.stackViewHeight = optionStackView.heightAnchor.constraint(equalToConstant: 0)
        newPostVC.stackViewHeight!.isActive = true
        
        //Meme Mode Button
        addSubview(memeModeButton)
        memeModeButton.centerYAnchor.constraint(equalTo: optionButton.centerYAnchor).isActive = true
        memeModeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        memeModeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        setMarkPostViewUI()
        setPostAnonymousViewUI()
    }
    
    func setMarkPostViewUI() {
        markPostView.addSubview(markPostSwitch)
        markPostSwitch.centerYAnchor.constraint(equalTo: markPostView.centerYAnchor).isActive = true
        markPostSwitch.leadingAnchor.constraint(equalTo: markPostView.leadingAnchor, constant: 5).isActive = true
        
        markPostView.addSubview(markPostSegmentControl)
        markPostSegmentControl.topAnchor.constraint(equalTo: markPostView.topAnchor, constant: 8).isActive = true
        markPostSegmentControl.leadingAnchor.constraint(equalTo: markPostSwitch.trailingAnchor, constant: 3).isActive = true
        markPostSegmentControl.bottomAnchor.constraint(equalTo: markPostView.bottomAnchor, constant: -8).isActive = true
        
        markPostView.addSubview(markPostLabel)
        markPostLabel.centerXAnchor.constraint(equalTo: markPostView.centerXAnchor).isActive = true
        markPostLabel.centerYAnchor.constraint(equalTo: markPostView.centerYAnchor).isActive = true
        
        markPostView.addSubview(markPostButton)
        markPostButton.centerYAnchor.constraint(equalTo: markPostView.centerYAnchor).isActive = true
        markPostButton.trailingAnchor.constraint(equalTo: markPostView.trailingAnchor, constant: -10).isActive = true
        markPostButton.leadingAnchor.constraint(equalTo: markPostSegmentControl.trailingAnchor, constant: 5).isActive = true
        markPostButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        markPostButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
    }
    
    func setPostAnonymousViewUI() {
        postAnonymousView.addSubview(postAnonymousSwitch)
        postAnonymousSwitch.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousSwitch.leadingAnchor.constraint(equalTo: postAnonymousView.leadingAnchor, constant: 5).isActive = true
        
        postAnonymousView.addSubview(postAnonymousLabel)
        postAnonymousLabel.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousLabel.centerXAnchor.constraint(equalTo: postAnonymousView.centerXAnchor).isActive = true
        
        postAnonymousView.addSubview(postAnonymousButton)
        postAnonymousButton.centerYAnchor.constraint(equalTo: postAnonymousView.centerYAnchor).isActive = true
        postAnonymousButton.trailingAnchor.constraint(equalTo: postAnonymousView.trailingAnchor, constant: -10).isActive = true
        postAnonymousButton.widthAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        postAnonymousButton.heightAnchor.constraint(equalToConstant: infoButtonSize).isActive = true
        
    }
    
    //MARK:- UI Init
    
    //MARK: Options
    
    let anonymousImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "mask")
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = .label
        } else {
            imageView.tintColor = .black
        }
        imageView.isHidden = true
        
        return imageView
    }()
    
    let anonymousNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 13)
        label.minimumScaleFactor = 0.5
        
        return label
    }()
    
    let optionButton: DesignableButton = {  // little Burger Menu
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            button.setTitleColor(.label, for: .normal)
            
        } else {
            button.setTitleColor(.black, for: .normal)
        }
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
        
        var color: UIColor!
        if #available(iOS 13.0, *) {
            color = .label
        } else {
            color = .black
        }
        
        let text = NSMutableAttributedString()
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: color]))
        text.append(NSAttributedString(string: "M", attributes: [NSAttributedString.Key.foregroundColor: tronColor]))
        
        button.setTitleColor(tronColor, for: .normal)
        button.setAttributedTitle(text, for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 14)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(memeModeTapped), for: .touchUpInside)
        
        return button
    }()
    
    //MARK: Mark Post
    let markPostView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let markPostLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("markPostButtonText", comment: "mark your post text")
        label.textAlignment = .center
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let markPostSwitch: UISwitch = {
        let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.addTarget(self, action: #selector(markPostSwitchChanged), for: .valueChanged)
        
        
        return switcher
    }()
    
    let markPostSegmentControl :UISegmentedControl = {
        let items = [NSLocalizedString("opinion", comment: "just opinion"), NSLocalizedString("sansational", comment: "sansational"), NSLocalizedString("edited", comment: "edited")]
        let control = UISegmentedControl(items: items)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.isHidden = true
        control.alpha = 0
        control.addTarget(self, action: #selector(markPostSegmentChanged), for: .touchUpInside)
        
        return control
    }()
    
    let markPostButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(markPostInfoButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    //MARK: Anonymous
    
    let postAnonymousView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        return view
    }()
    
    let postAnonymousLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = NSLocalizedString("post_anonymous_label", comment: "post anonymous")
        label.textAlignment = .center
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        
        return label
    }()
    
    let postAnonymousSwitch: UISwitch = {
       let switcher = UISwitch()
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.addTarget(self, action: #selector(postAnonymousSwitchChanged), for: .valueChanged)
        
        return switcher
    }()
    
    let postAnonymousButton :DesignableButton = {
        let button = DesignableButton(type: .detailDisclosure)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(postAnonymousButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
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
    
    @objc func postAnonymousSwitchChanged() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.postAnonymousSwitchChanged()
    }
    
    @objc func postAnonymousButtonPressed() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.postAnonymousButtonPressed()
    }
    
    //MARK: Mark Post
    
    @objc func markPostSegmentChanged() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.markPostSegmentChanged()
    }
    
    @objc func markPostInfoButtonPressed() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.markPostInfoButtonPressed()
    }
    
    @objc func markPostSwitchChanged() {
        guard let newPostVC = newPostVC else {return}
        newPostVC.markPostSwitchChanged()
    }
}
