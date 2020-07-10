//
//  FactDetailViewController.swift
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

class FactDetailViewController: UIViewController, ReachabilityObserverDelegate {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var downvoteButton: DesignableButton!
    @IBOutlet weak var upvoteButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var upvoteCountLabel: UILabel!
    @IBOutlet weak var downvoteCountLabel: UILabel!
    @IBOutlet weak var commentTableView: CommentTableView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerTopicLabel: UILabel!
    @IBOutlet weak var headerProContraLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var floatingCommentView: CommentAnswerView?
    
    var argument: Argument?
    var fact: Fact?
    
    let db = Firestore.firestore()
    var tipView: EasyTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setDataUp()
        
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        scrollViewTap.cancelsTouchesInView = false  // Otherwise the tap on the TableViews are not recognized
        scrollView.addGestureRecognizer(scrollViewTap)
        
        commentTableView.initializeCommentTableView(section: .argument, notificationRecipients: nil)
        commentTableView.commentDelegate = self
        if let argument = argument {
            commentTableView.argument = argument
        }
        
        createFloatingCommentView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let view = floatingCommentView {
            view.removeFromSuperview()
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
        let height = UIScreen.main.bounds.height
        floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: height-60, width: self.view.frame.width, height: 60))
        floatingCommentView!.delegate = self
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(floatingCommentView!)
        }
    }
    
    func setDataUp() {
        guard let argument = argument,
        let fact = fact
            else { return }
        
        upvoteCountLabel.text = String(argument.upvotes)
        downvoteCountLabel.text = String(argument.downvotes)
        titleLabel.text = argument.title
        descriptionLabel.text = argument.description
        
        if let url = URL(string: fact.imageURL) {
            headerImageView.sd_setImage(with: url, completed: nil)
        }
        headerTopicLabel.text = fact.title
        if let names = fact.factDisplayNames {
            self.headerProContraLabel.text = getDisplayString(displayNames: names, proOrContra: argument.proOrContra)
        }
    }
    
    func getDisplayString(displayNames: FactDisplayName, proOrContra: String) -> String {
        switch displayNames {
        case .advantageDisadvantage:
            if proOrContra == "pro" {
                return "Vorteile"
            } else {
               return "Nachteile"
            }
        case .confirmDoubt:
           if proOrContra == "pro" {
                return "Bestätigung"
            } else {
               return "Zweifel"
            }
        case .proContra:
            if proOrContra == "pro" {
                return "Pro"
            } else {
               return "Contra"
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
    
    enum vote {
        case upvote
        case downvote
    }
    
    func voted(kindOfVote: vote) {
        if isConnected() {
        if let argument = argument, let fact = fact {
            let ref = db.collection("Facts").document(fact.documentID).collection("arguments").document(argument.documentID)
            
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
            
            ref.setData([voteString: voteCount], mergeFields: [voteString]) { (err) in
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
            if let vc = segue.destination as? SourceTableViewController {
                vc.argument = self.argument
                vc.fact = self.fact
            }
        }
        if segue.identifier == "toArgumentTableView" {
            if let argumentVC = segue.destination as? ArgumentTableViewController {
                argumentVC.argument = self.argument
                argumentVC.fact = self.fact
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

extension FactDetailViewController: CommentTableViewDelegate, CommentViewDelegate {
    
    func recipientChanged(isActive: Bool, userUID: String) {
        print("COming soon")
    }
    
    func sendButtonTapped(text: String, isAnonymous: Bool) {
        floatingCommentView!.resignFirstResponder()
        commentTableView.saveCommentInDatabase(bodyString: text, isAnonymous: isAnonymous)
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
        let reportViewController = storyBoard.instantiateViewController(withIdentifier: "reportVC") as! MeldenViewController
        reportViewController.reportComment = true
        reportViewController.modalTransitionStyle = .coverVertical
        reportViewController.modalPresentationStyle = .overFullScreen
        self.present(reportViewController, animated: true, completion: nil)
    }
    
    func commentGotDeleteRequest(comment: Comment) {
        self.deleteAlert(title: "Kommentar löschen?", message: "Möchtest du das Kommentar wirklich löschen? Dieser Vorgang kann nicht rückgängig gemacht werden.", delete:  { (delete) in
            if delete {
                
                HandyHelper().deleteCommentInFirebase(comment: comment)
            }
        })
    }
    
    func toUserTapped(user: User) {
        performSegue(withIdentifier: "toUserSegue", sender: user)
    }
    
}
