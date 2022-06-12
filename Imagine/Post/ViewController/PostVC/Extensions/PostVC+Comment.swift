//
//  PostVC+Comment.swift
//  Imagine
//
//  Created by Don Malte on 22.09.21.
//  Copyright © 2021 Malte Schoppe. All rights reserved.
//

import UIKit
import BSImagePicker
import Photos
import CropViewController

extension PostViewController: CommentTableViewDelegate, CommentViewDelegate {
    
    func notLoggedIn() {
        self.notLoggedInAlert()
    }
    
    func doneSaving() {
        if let view = self.floatingCommentView {
            view.doneSaving()
        }
    }
    
    func sendButtonTapped(text: String, isAnonymous: Bool, answerToComment: Comment?) {
        
        commentTableView.saveCommentInDatabase(bodyString: text, isAnonymous: isAnonymous, answerToComment: answerToComment)
    }
    
    func recipientChanged(isActive: Bool, userUID: String) {
        guard let post = post, var recipients = post.notificationRecipients else { return }
        
        if isActive {
            recipients.append(userUID)
        } else {
            let newList = recipients.filter { $0 != userUID }
            post.notificationRecipients = newList
        }
        
        post.notificationRecipients = recipients
    }
    
    func notAllowedToComment() {
        if let view = floatingCommentView {
            view.answerTextField.text = ""
        }
    }
    
    func commentTypingBegins() {
        
    }
    
    func commentGotReported(comment: Comment) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let reportViewController = storyBoard.instantiateViewController(withIdentifier: "reportVC") as! ReportViewController
        reportViewController.reportComment = true
        reportViewController.modalTransitionStyle = .coverVertical
        reportViewController.modalPresentationStyle = .overFullScreen
        self.present(reportViewController, animated: true, completion: nil)
    }
    
    func commentGotDeleteRequest(comment: Comment, answerToComment: Comment?) {
        self.deleteAlert(title: NSLocalizedString("delete_comment_alert_title", comment: "title"), message: NSLocalizedString("delete_comment_alert_message", comment: "cant be redeemed"), delete:  { (delete) in
            if delete {
                HandyHelper.shared.deleteCommentInFirebase(comment: comment, answerToComment: answerToComment)
                self.commentTableView.deleteCommentFromTableView(comment: comment, answerToComment: answerToComment)
            }
        })
    }
    
    func toUserTapped(user: User) {
        performSegue(withIdentifier: "toUserSegue", sender: user)
    }
    
    func answerCommentTapped(comment: Comment) {
        if let answerView = self.floatingCommentView {
            answerView.addRecipientField(comment: comment)
        }
    }
}
