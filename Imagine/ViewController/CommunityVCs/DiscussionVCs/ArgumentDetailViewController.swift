//
//  ArgumentDetailViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ArgumentDetailViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var sourceTextView: UITextView!
    @IBOutlet weak var sourceTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var showSourceButton: DesignableButton!
    @IBOutlet weak var commentTableView: CommentTableView!
    
    var source: Source?
    var argument: Argument?
    
    var floatingCommentView: CommentAnswerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sourceTextView.delegate = self

        setUpView()
        
        if let source = source {
            commentTableView.initializeCommentTableView(section: .source, notificationRecipients: nil)
            commentTableView.commentDelegate = self
            commentTableView.source = source
        } else if let argument = argument {
            commentTableView.initializeCommentTableView(section: .counterArgument, notificationRecipients: nil)
            commentTableView.commentDelegate = self
            commentTableView.counterArgument = argument
        }
        
        createFloatingCommentView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let commentView = floatingCommentView {
            commentView.addKeyboardObserver()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let commentView = floatingCommentView {
            commentView.removeKeyboardObserver()
        }
    }

    
    func setUpView() {
        if let source = source {
            let length = source.title.count+1
            
            let attributedString = NSMutableAttributedString(string: "Go to source: \(source.title)")
            attributedString.addAttribute(.link, value: source.source, range: NSRange(location: 13, length: length))
            
            sourceTextView.attributedText = attributedString
            
            self.titleLabel.text = source.title
            self.descriptionLabel.text = source.description
        } else if let argument = argument {
            self.sourceTextViewHeightConstraint.constant = 0
            self.showSourceButton.isHidden = true
            self.titleLabel.text = argument.title
            self.descriptionLabel.text = argument.description
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let view = floatingCommentView {
            view.answerTextField.resignFirstResponder()
        }
    }
    
    // To open the link
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        UIApplication.shared.open(URL)
        return false
    }
    
    @IBAction func showSourceButtonTapped(_ sender: Any) {
        if let source = source {
            performSegue(withIdentifier: "goToLink", sender: source.source)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToLink" {
            if let webVC = segue.destination as? WebViewController {
                if let link = sender as? String {
                    webVC.link = link
                }
            }
        }
        if segue.identifier == "toUserSegue" {
            if let chosenUser = sender as? User {
                if let userVC = segue.destination as? UserFeedTableViewController {
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                    
                }
            }
        }
    }
    
    
    func createFloatingCommentView() {
        let viewHeight = self.view.frame.height
        
        if floatingCommentView == nil {
            let commentViewHeight: CGFloat = 60
            floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: viewHeight-commentViewHeight, width: self.view.frame.width, height: commentViewHeight))
            
            
            floatingCommentView!.delegate = self
            self.view.addSubview(floatingCommentView!)
            
            floatingCommentView!.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            floatingCommentView!.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            let bottomConstraint = floatingCommentView!.bottomAnchor.constraint(equalTo: self.view
                                                                                    .bottomAnchor)
                bottomConstraint.isActive = true
            floatingCommentView!.bottomConstraint = bottomConstraint
            floatingCommentView!.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            floatingCommentView!.addKeyboardObserver()
            
            self.view.bringSubviewToFront(floatingCommentView!)
            self.view.layoutIfNeeded()
        }
    }

}

extension ArgumentDetailViewController: CommentViewDelegate, CommentTableViewDelegate {
    
    func heightChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.view.layoutSubviews()
        }
    }
    
    func recipientChanged(isActive: Bool, userUID: String) {
        print("COming soon")
    }
    
    func sendButtonTapped(text: String, isAnonymous: Bool, answerToComment: Comment?) {
        floatingCommentView!.resignFirstResponder()
        commentTableView.saveCommentInDatabase(bodyString: text, isAnonymous: isAnonymous, answerToComment: answerToComment)
    }
    
    func commentTypingBegins() {
        
    }
    
    func doneSaving() {
        if let view = floatingCommentView {
            view.doneSaving()
        }
    }
    
    func notLoggedIn() {
        self.notLoggedInAlert()
    }
    
    func notAllowedToComment() {
        if let view = floatingCommentView {
            view.answerTextField.text = ""
        }
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
        self.deleteAlert(title: NSLocalizedString("delete_comment_alert_title", comment: "delete comment?"), message: NSLocalizedString("delete_comment_alert_message", comment: "sure to delete?"), delete:  { (delete) in
            if delete {
                
                HandyHelper().deleteCommentInFirebase(comment: comment, answerToComment: answerToComment)
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
