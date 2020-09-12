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
    
    override func viewWillDisappear(_ animated: Bool) {
        if let view = floatingCommentView {
            view.removeFromSuperview()
        }
    }
    
    func setUpView() {
        if let source = source {
            
            let length = source.title.count+1
            
            let attributedString = NSMutableAttributedString(string: "Gehe zur Quelle: \(source.title)")
            attributedString.addAttribute(.link, value: source.source, range: NSRange(location: 16, length: length))
            
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
        let height = UIScreen.main.bounds.height
        floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: height-60, width: self.view.frame.width, height: 60))
        floatingCommentView!.delegate = self
        
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(floatingCommentView!)
        }
    }

}

extension ArgumentDetailViewController: CommentViewDelegate, CommentTableViewDelegate {
    
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
        let reportViewController = storyBoard.instantiateViewController(withIdentifier: "reportVC") as! MeldenViewController
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
