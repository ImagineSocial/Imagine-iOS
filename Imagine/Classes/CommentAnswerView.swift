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
    func sendButtonTapped(text: String, isAnonymous: Bool, answerToComment: Comment?)
    func commentTypingBegins()
}

class CommentAnswerView: UIView, UITextViewDelegate {
    
    var delegate: CommentViewDelegate?
    
    var isAnonymous = false
    var answerToCommentView: UIView?
    
    var answerToComment: Comment?
    
    let messageTextViewMaxHeight: CGFloat = 80
    
    let answerPlaceholderText = NSLocalizedString("comment_answer_placeholder", comment: "say something about it")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            self.backgroundColor = .secondarySystemBackground
        } else {
            self.backgroundColor = .ios12secondarySystemBackground
        }
        answerTextField.delegate = self
        answerTextField.text = answerPlaceholderText
                
        addSubview(answerTextField)
        addSubview(sendButton)
        addSubview(anonymousButton)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardGotClosed), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.contentSize.height >= self.messageTextViewMaxHeight {
            textView.isScrollEnabled = true
        } else {
//            textView.frame.size.height = textView.contentSize.height
            textView.isScrollEnabled = false
         }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.commentTypingBegins()
        
        if textView.text == answerPlaceholderText {
            answerTextField.text = ""
        }
        
        if #available(iOS 13.0, *) {
            textView.textColor = .label
        } else {
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = answerPlaceholderText
            
            if #available(iOS 13.0, *) {
                textView.textColor = .secondaryLabel
            } else {
                textView.textColor = .lightGray
            }
        }
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
            delegate?.sendButtonTapped(text: answer, isAnonymous: isAnonymous, answerToComment: answerToComment)
            answerTextField.resignFirstResponder()
        }
    }
    
    func doneSaving() {
        sendButton.isEnabled = true
        answerTextField.text = ""
        answerTextField.frame.size.height = answerTextField.contentSize.height
        self.layoutSubviews()
        if let _ = answerToComment {
            cancelRecipientTapped() // Remove the view, if there is any
        }
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
        
        answerTextField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20).isActive = true
//        answerTextField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        answerTextField.heightAnchor.constraint(lessThanOrEqualToConstant: 80).isActive = true
        answerTextField.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
        answerTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10).isActive = true
        answerTextField.leadingAnchor.constraint(equalTo: anonymousButton.trailingAnchor, constant: 10).isActive = true
        
    }
    
    let recipientBackgroundViewHeight: CGFloat = 35
    
    func addRecipientField(comment: Comment) {
        
        if let _ = self.answerToComment {
            cancelRecipientTapped()
        }
        
        self.answerToCommentView = recipientBackgroundView
        self.answerToComment = comment
        
        self.addSubview(recipientBackgroundView)
        let separatorView = HairlineView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            separatorView.backgroundColor = .separator
        } else {
            separatorView.backgroundColor = .black
        }
        recipientBackgroundView.addSubview(separatorView)
        recipientBackgroundView.addSubview(recipientLabel)
        recipientBackgroundView.addSubview(cancelRecipientButton)
        recipientBackgroundView.addSubview(recipientNameLabel)
        
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: recipientBackgroundView.topAnchor).isActive = true
        
        recipientBackgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        recipientBackgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        recipientBackgroundView.bottomAnchor.constraint(equalTo: self.answerTextField.topAnchor, constant: -5).isActive = true
        recipientBackgroundView.heightAnchor.constraint(equalToConstant: recipientBackgroundViewHeight).isActive = true
        
        cancelRecipientButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        cancelRecipientButton.centerYAnchor.constraint(equalTo: recipientBackgroundView.centerYAnchor).isActive = true
        cancelRecipientButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        cancelRecipientButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        cancelRecipientButton.addTarget(self, action: #selector(cancelRecipientTapped), for: .touchUpInside)
        
        recipientLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        recipientLabel.centerYAnchor.constraint(equalTo: recipientBackgroundView.centerYAnchor).isActive = true
        
        recipientNameLabel.leadingAnchor.constraint(equalTo: recipientLabel.trailingAnchor, constant: 2).isActive = true
        recipientNameLabel.centerYAnchor.constraint(equalTo: recipientBackgroundView.centerYAnchor).isActive = true
        recipientNameLabel.trailingAnchor.constraint(equalTo: cancelRecipientButton.leadingAnchor, constant: -10).isActive = true
        
        if let user = comment.user {
            recipientNameLabel.text = user.displayName
        } else {
            recipientNameLabel.text = comment.text
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.recipientBackgroundView.alpha = 1
        }) { (_) in
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y-self.recipientBackgroundViewHeight, width: self.frame.width, height: self.frame.height+self.recipientBackgroundViewHeight)
            self.layoutIfNeeded()
        }
        
    }
    
    @objc func cancelRecipientTapped() {
        print("Cancel tapped")
        if let view = answerToCommentView {
            self.answerToComment = nil
            
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y+recipientBackgroundViewHeight, width: self.frame.width, height: self.frame.height-recipientBackgroundViewHeight)
            self.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.3, animations: {
                view.alpha = 0
            }) { (_) in
                view.removeFromSuperview()
            }
        }
    }
    
    //MARK:- ViewMovesWithKeyboard
    
    var keyboardheight:CGFloat = 0
    
    override func willMove(toSuperview newSuperview: UIView?) {
        //remove the notification listener wenn the view is exited
        if newSuperview == nil {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
    
    
    @objc func keyboardWillChange(notification: NSNotification) {
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let heightDifference = keyboardSize.height-self.keyboardheight
                
                if heightDifference >= 200 {    // opens up
                    self.keyboardheight = keyboardSize.height-10
                    frame.origin.y = frame.origin.y-(keyboardheight)
                } else {    // Changes Size
                    frame.origin.y = frame.origin.y-(heightDifference)
                    self.keyboardheight = self.keyboardheight+heightDifference
                }
            }
        
    }
    
    @objc func keyboardWillHide() {
        frame.origin.y = frame.origin.y+(keyboardheight)
    }
    
    @objc func keyboardGotClosed() {
        self.keyboardheight = 0
    }
    
    //MARK:-UI
    
    let anonymousButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "mask"), for: .normal)
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(anonymousTapped), for: .touchUpInside)
        button.imageEdgeInsets = UIEdgeInsets(top: 3, left: 5, bottom: 5, right: 5)
        
        return button
    }()
    
    let answerTextField: UITextView = {
        let field = UITextView()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .white
        field.layer.cornerRadius = 10
        field.font = UIFont(name: "IBMPlexSans", size: 14)
        field.isScrollEnabled = false

        if #available(iOS 13.0, *) {
            field.backgroundColor = .systemBackground
            field.textColor = .secondaryLabel
        } else {
            field.backgroundColor = .white
            field.textColor = .lightGray
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
    
    let recipientBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        view.alpha = 0
        
        return view
    }()
    
    let recipientLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans", size: 13)
        label.text = NSLocalizedString("comment_indented_answer_label", comment: "answer to:")
        
        return label
    }()
    
    let recipientNameLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "IBMPlexSans-Medium", size: 13)
        
        return label
    }()
    
    let cancelRecipientButton: DesignableButton = {
       let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "DismissTemplate"), for: .normal)
        
        return button
    }()
    
}
