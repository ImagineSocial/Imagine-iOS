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
    func sendButtonTapped(text: String)
    func commentTypingBegins()
}

class CommentAnswerView: UIView, UITextFieldDelegate {
    
    var delegate: CommentViewDelegate?
    let db = Firestore.firestore()
    
    var post: Post?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 13.0, *) {
            self.backgroundColor = .systemBackground
        } else {
            self.backgroundColor = .white
        }
        answerTextField.delegate = self
                
        addSubview(answerTextField)
        addSubview(sendButton)
        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = UIImage(named: "messageBubble")
        view.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            view.tintColor = .label
        } else {
            view.tintColor = .white
        }
        
        return view
    }()
    
    let answerTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .white
        field.layer.cornerRadius = 10
        field.placeholder = " Sag etwas dazu..."
        if #available(iOS 13.0, *) {
            field.backgroundColor = .secondarySystemBackground
        } else {
            field.backgroundColor = .lightGray
        }
        
        return field
    }()
    
    let sendButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        } else {
            button.setImage(UIImage(named: "upvote"), for: .normal)
        }
        button.tintColor = Constants.imagineColor
        button.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        
        return button
    }()
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.commentTypingBegins()
    }
    
    @objc func sendTapped() {
        if let answer = answerTextField.text {
            delegate?.sendButtonTapped(text: answer)
            answerTextField.resignFirstResponder()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        sendButton.centerYAnchor.constraint(equalTo: answerTextField.centerYAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 35).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        
        imageView.centerYAnchor.constraint(equalTo: answerTextField.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        
        answerTextField.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        answerTextField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        answerTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10).isActive = true
        answerTextField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10).isActive = true
        
    }
    
    
    
}
