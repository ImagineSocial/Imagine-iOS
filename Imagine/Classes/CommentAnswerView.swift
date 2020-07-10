//
//  CommentTableViewFooter.swift
//  Imagine
//
//  Created by Malte Schoppe on 17.02.20.
//  Copyright © 2020 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

protocol CommentViewDelegate {
    func sendButtonTapped(text: String, isAnonymous: Bool)
    func commentTypingBegins()
}

class CommentAnswerView: UIView, UITextFieldDelegate {
    
    var delegate: CommentViewDelegate?
    let db = Firestore.firestore()
    
    var isAnonymous = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 13.0, *) {
            self.backgroundColor = .secondarySystemBackground
        } else {
            self.backgroundColor = .ios12secondarySystemBackground
        }
        answerTextField.delegate = self
                
        addSubview(answerTextField)
        addSubview(sendButton)
        addSubview(anonymousButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let anonymousButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mask"), for: .normal)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(anonymousTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        
        return button
    }()
    
    let answerTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .white
        field.layer.cornerRadius = 10
        field.placeholder = " Sag etwas dazu..."
        if #available(iOS 13.0, *) {
            field.backgroundColor = .systemBackground
        } else {
            field.backgroundColor = .white
        }
        
        return field
    }()
    
    let sendButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "sendButton"), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        return button
    }()
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.commentTypingBegins()
    }
    
    @objc func anonymousTapped() {
        if isAnonymous {
            self.isAnonymous = false
            anonymousButton.tintColor = .imagineColor
        } else {
            self.isAnonymous = true
            anonymousButton.tintColor = Constants.green
        }
    }
    
    @objc func sendTapped() {
        if let answer = answerTextField.text, answer != "" {
            sendButton.isEnabled = false
            delegate?.sendButtonTapped(text: answer, isAnonymous: isAnonymous)
            answerTextField.resignFirstResponder()
        }
    }
    
    func doneSaving() {
        sendButton.isEnabled = true
        answerTextField.text = ""
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        sendButton.centerYAnchor.constraint(equalTo: answerTextField.centerYAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        
        anonymousButton.centerYAnchor.constraint(equalTo: answerTextField.centerYAnchor).isActive = true
        anonymousButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        anonymousButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        anonymousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        
        answerTextField.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        answerTextField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        answerTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10).isActive = true
        answerTextField.leadingAnchor.constraint(equalTo: anonymousButton.trailingAnchor, constant: 10).isActive = true
        
    }
    
    //MARK:- ViewMovesWithKeyboard
    
    var keyboardheight:CGFloat = 0
    
    @objc func keyboardWillHide() {
        
        frame.origin.y = frame.origin.y+(keyboardheight*2)
        
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    
    @objc func keyboardWillChange(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                self.keyboardheight = keyboardSize.height-10
                frame.origin.y = frame.origin.y-(keyboardheight)
        }
    }
    
}
