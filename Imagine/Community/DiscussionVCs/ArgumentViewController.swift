//
//  ArgumentViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 23.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import EasyTipView

enum vote {
    case upvote
    case downvote
}

class ArgumentViewController: UIViewController, ReachabilityObserverDelegate {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var downvoteButton: DesignableButton!
    @IBOutlet weak var upvoteButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var upvoteCountLabel: UILabel!
    @IBOutlet weak var downvoteCountLabel: UILabel!
    @IBOutlet weak var commentTableView: CommentTableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    var floatingCommentView: CommentAnswerView?
    
    var argument: Argument?
    var community: Community?
    
    let db = FirestoreRequest.shared.db
    var tipView: EasyTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setDataUp()
        
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        scrollViewTap.cancelsTouchesInView = false  // Otherwise the tap on the TableViews are not recognized
        scrollView.addGestureRecognizer(scrollViewTap)
        
        scrollView.delegate = self
        
        commentTableView.initializeCommentTableView(section: .argument, notificationRecipients: nil)
        commentTableView.commentDelegate = self
        if let argument = argument {
            commentTableView.argument = argument
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
        
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    @objc func scrollViewTapped() {
        if let view = floatingCommentView {
            view.answerTextField.resignFirstResponder()
        }
    }
    
    func createFloatingCommentView() {
        let viewHeight = self.view.frame.height
        
        if floatingCommentView == nil {
            let commentViewHeight: CGFloat = 60
            floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: viewHeight-commentViewHeight, width: self.view.frame.width, height: commentViewHeight))
            
            
            floatingCommentView!.delegate = self
            self.contentView.addSubview(floatingCommentView!)
            
            floatingCommentView!.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
            floatingCommentView!.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            let bottomConstraint = floatingCommentView!.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
                bottomConstraint.isActive = true
            floatingCommentView!.bottomConstraint = bottomConstraint
            floatingCommentView!.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            floatingCommentView!.addKeyboardObserver()
            
            self.contentView.bringSubviewToFront(floatingCommentView!)
        }
    }
    
    func setDataUp() {
        guard let argument = argument, let community = community else { return }
        
        upvoteCountLabel.text = String(argument.upvotes)
        downvoteCountLabel.text = String(argument.downvotes)
        titleLabel.text = argument.title
        descriptionLabel.text = argument.description
    }
    
    func getDisplayString(displayNames: FactDisplayName, proOrContra: String) -> String {
        switch displayNames {
        case .advantageDisadvantage:
            if proOrContra == "pro" {
                return NSLocalizedString("discussion_advantage", comment: "advantage")
            } else {
                return NSLocalizedString("discussion_disadvantage", comment: "disadvantage")
            }
        case .confirmDoubt:
            if proOrContra == "pro" {
                return NSLocalizedString("discussion_proof", comment: "proof")
            } else {
                return NSLocalizedString("discussion_doubt", comment: "doubt")
            }
        case .proContra:
            if proOrContra == "pro" {
                return NSLocalizedString("discussion_pro", comment: "pro")
            } else {
                return NSLocalizedString("discussion_contra", comment: "contra")
            }
        }
    }
    
    @IBAction func downVoteButtonTapped(_ sender: Any) {
        voted(kindOfVote: .downvote)
    }
    
    @IBAction func upvoteButtonTapped(_ sender: Any) {
        voted(kindOfVote: .upvote)
    }
    
    func reachabilityChanged(_ isReachable: Bool) {
        print("Connection? :", isReachable)
    }
    
    
    
    func voted(kindOfVote: vote) {
        if isConnected() {
            if let argument = argument, let community = community {
                var collectionRef: CollectionReference!
                if community.language == .english {
                    collectionRef = db.collection("Data").document("en").collection("topics")
                } else {
                    collectionRef = db.collection("Facts")
                }
                let ref = collectionRef.document(community.documentID).collection("arguments").document(argument.documentID)
                
                var voteString = ""
                var voteCount = 0
                
                switch kindOfVote {
                case .downvote:
                    voteString = "downvotes"
                    voteCount = argument.downvotes+1
                    argument.downvotes = voteCount
                case .upvote:
                    voteString = "upvotes"
                    voteCount = argument.upvotes+1
                    argument.upvotes = voteCount
                }
                
                ref.updateData([voteString: voteCount]) { (err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        self.ready()
                    }
                }
            }
        } else {
            self.alert(message: "Du brauchst eine aktive Internet Verbindung um wählen zu können!")
        }
    }

    func ready() {
        if let argument = argument {
            self.upvoteCountLabel.text = String(argument.upvotes)
            self.downvoteCountLabel.text = String(argument.downvotes)
            self.upvoteButton.isEnabled = false
            self.downvoteButton.isEnabled = false
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSourceTableView" {
            if let vc = segue.destination as? ArgumentSourceTableVC {
                vc.argument = self.argument
                vc.fact = self.community
            }
        }
        if segue.identifier == "toArgumentTableView" {
            if let argumentVC = segue.destination as? ArgumentTableVC {
                argumentVC.argument = self.argument
                argumentVC.fact = self.community
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
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.argumentDetailText)
            tipView!.show(forItem: infoButton)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
}

extension ArgumentViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            if let view = floatingCommentView {
                let offset = scrollView.contentOffset.y
                let screenHeight = self.view.frame.height
                
                view.adjustPositionForScroll(contentOffset: offset, screenHeight: screenHeight)
            }
        }
    }
}

extension ArgumentViewController: CommentTableViewDelegate, CommentViewDelegate {
    
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
    
    func notAllowedToComment() {
        if let view = floatingCommentView {
            view.answerTextField.text = ""
        }
    }
    
    func doneSaving() {
        if let view = floatingCommentView {
            view.doneSaving()
        }
    }
    
    func notLoggedIn() {
        self.notLoggedInAlert()
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
        self.deleteAlert(title: NSLocalizedString("delete_comment_alert_title", comment: "delete comment?"), message: NSLocalizedString("delete_comment_alert_message", comment: "cant be redeemememed"), delete:  { (delete) in
            if delete {
                HandyHelper.shared.deleteCommentInFirebase(comment: comment, answerToComment: answerToComment)
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
