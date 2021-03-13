//
//  CampaignViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 18.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import EasyTipView

class CampaignViewController: UIViewController, ReachabilityObserverDelegate {
    
    //MARK:- IBOutlets
    @IBOutlet weak var shortBodyLabel: UILabel!
    @IBOutlet weak var longBodyLabel: UILabel!
    @IBOutlet weak var createDateLabel: UILabel!
    @IBOutlet weak var supporterLabel: UILabel!
    @IBOutlet weak var oppositionLabel: UILabel!
    @IBOutlet weak var supportButton: DesignableButton!
    @IBOutlet weak var oppositionButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var commentTableView: CommentTableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    //MARK:- Variables
    private let db = Firestore.firestore()
    
    private var floatingCommentView: CommentAnswerView?
    
    private var tipView: EasyTipView?
    
    var campaign: Campaign?
    
    var campaignID: String? {
        didSet {
            if let id = campaignID {
                
                let imagineDataRequest = ImagineDataRequest()
                imagineDataRequest.getCampaign(documentID: id) { (campaign) in
                    if let campaign = campaign {
                        self.campaign = campaign
                        self.showCampaign()
                    } else {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    //MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        showCampaign()
        
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        scrollViewTap.cancelsTouchesInView = false  // Otherwise the tap on the TableViews are not recognized
        scrollView.addGestureRecognizer(scrollViewTap)
        
        scrollView.delegate = self
        
        commentTableView.initializeCommentTableView(section: .proposal, notificationRecipients: nil)
        commentTableView.commentDelegate = self
        
        createFloatingCommentView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let commentView = floatingCommentView {
            commentView.addKeyboardObserver()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
        
        if let commentView = floatingCommentView {
            commentView.removeKeyboardObserver()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    
    
    func showCampaign() {
        guard let campaign = campaign else {
            return
        }
        shortBodyLabel.text = campaign.cellText
        longBodyLabel.text = campaign.descriptionText
        createDateLabel.text = campaign.createDate
        supporterLabel.text = "\(campaign.supporter) Supporter"
        oppositionLabel.text = "\(campaign.opposition) Vetos"
        navigationItem.title = campaign.title
        
        commentTableView.proposal = campaign
    }
    
    @IBAction func supportPressed(_ sender: Any) {
        self.checkIfAllowedToVote(supporter: true)
    }
    
    @IBAction func dontSupportPressed(_ sender: Any) {
        self.checkIfAllowedToVote(supporter: false)
    }
    
    func reachabilityChanged(_ isReachable: Bool) {
        print("No Connection")
    }
    
    func voted(supporter: Bool) {
        guard let campaign = campaign else {
            return
        }
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection("campaigns")
        } else {
            collectionRef = db.collection("Campaigns")
        }
        let postRef = collectionRef.document(campaign.documentID)
        
        if let user = Auth.auth().currentUser {
            if supporter {
                let newSupporter = campaign.supporter+1 // Could be the old number if anyone votes in between
                campaign.supporter = newSupporter
                
                postRef.updateData(["supporter": newSupporter]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        self.registerVoter(userUID: user.uid)
                    }
                }
            } else {
                let newVetos = campaign.opposition+1 // Could be the old number if anyone votes in between
                campaign.opposition = newVetos
                
                postRef.updateData(["opposition": newVetos]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        self.registerVoter(userUID: user.uid)
                    }
                }
            }
        }
    }
    
    func registerVoter(userUID: String) {
        
        guard let campaign = campaign else {
            return
        }
        
        var collectionRef: CollectionReference!
        let language = LanguageSelection().getLanguage()
        if language == .english {
            collectionRef = db.collection("Data").document("en").collection("campaigns")
        } else {
            collectionRef = db.collection("Campaigns")
        }
        let postRef = collectionRef.document(campaign.documentID)
        
        postRef.updateData([
            "voters": FieldValue.arrayUnion([userUID]) // Add the person as a voter
        ]) { (err) in
            if let error = err {
                print("We have an error: \(error.localizedDescription)")
            } else {
                self.view.activityStopAnimating()
                self.alert(message: NSLocalizedString("thanks_for_vote_message", comment: ""), title: NSLocalizedString("thanks_for_support", comment: ""))
                self.oppositionLabel.text = "\(campaign.opposition) Vetos"
                self.supporterLabel.text = "\(campaign.supporter) Supporter"
                self.supportButton.isEnabled = false
                self.oppositionButton.isEnabled = false
                print("Document successfully updated")
            }
        }
        
    }
    
    func checkIfAllowedToVote(supporter: Bool) {
        
        guard let campaign = campaign else {
            return
        }
        
        if isConnected() {
            if let user = Auth.auth().currentUser {
                var collectionRef: CollectionReference!
                let language = LanguageSelection().getLanguage()
                if language == .english {
                    collectionRef = db.collection("Data").document("en").collection("campaigns")
                } else {
                    collectionRef = db.collection("Campaigns")
                }
                let voteRef = collectionRef.document(campaign.documentID)
                voteRef.getDocument { (doc, err) in
                    if let error = err {
                        print("We have an error: \(error.localizedDescription)")
                    } else {
                        if let document = doc {
                            if let docData = document.data() {
                                if let voters = docData["voters"] as? [String] {
                                    for voter in voters {
                                        if voter == user.uid {
                                            self.alert(message: NSLocalizedString("already_voted_message", comment: "already voted"), title: NSLocalizedString("already_voted_title", comment: ""))
                                            return
                                        }
                                    }
                                    // Not in the list
                                    self.allowedToVote(supporter: supporter)
                                }
                            }
                        }
                    }
                }
            } else {
                self.notLoggedInAlert()
            }
        } else {
            self.alert(message: "Du brauchst eine aktive Internet Verbindung um wählen zu können!")
        }
    }
    
    func allowedToVote(supporter: Bool) {
        let alertController = UIAlertController(title: NSLocalizedString("sure_to_vote_title", comment: ""), message: NSLocalizedString("sure_to_vote_message", comment: ""), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("not_sure", comment: ""), style: .destructive, handler: { (_) in
            alertController.dismiss(animated: true, completion: nil)
        })
        let stayAction = UIAlertAction(title: NSLocalizedString("i_am_sure", comment: ""), style: .cancel) { (_) in
            self.voted(supporter: supporter)
        }
        alertController.addAction(stayAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserSegue" {
            if let chosenUser = sender as? User {
                if let userVC = segue.destination as? UserFeedTableViewController {
                    userVC.userOfProfile = chosenUser
                    userVC.currentState = .otherUser
                }
            }
        }
    }
    
    @IBAction func reportPressed(_ sender: Any) {
    }
    
    
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.campaignDetailText)
            tipView!.show(forItem: infoButton)
        }
    }
    
}

extension CampaignViewController: UIScrollViewDelegate {
    
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

extension CampaignViewController: CommentViewDelegate, CommentTableViewDelegate {
    
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
        self.deleteAlert(title: NSLocalizedString("delete_comment_alert_title", comment: ""), message: NSLocalizedString("delete_comment_alert_message", comment: "you sure? cant be returned"), delete:  { (delete) in
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
