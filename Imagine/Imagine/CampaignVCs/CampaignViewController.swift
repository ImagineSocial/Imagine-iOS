//
//  CampaignViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 18.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import EasyTipView

class CampaignViewController: UIViewController, ReachabilityObserverDelegate {
    
    //MARK: - Elements
    
    let containerView = BaseView()
    let spaceView = BaseView()
    let separatorView = HairlineView(backgroundColor: .separator)
    
    let titleLabel = BaseTextLabel(font: UIFont.standard(with: .semibold, size: 20))
    let summaryLabel = BaseTextLabel(font: UIFont.standard(with: .medium, size: 16))
    let descriptionLabel = BaseTextLabel(font: UIFont.standard(with: .regular, size: 14))
    let campaignDateLabel = BaseLabel(font: UIFont.standard(with: .medium, size: 12))
    let campaignTypeLabel = BaseLabel(font: UIFont.standard(with: .medium, size: 14))
    let supporterLabel = BaseLabel()
    let oppositionLabel = BaseLabel()
    let supportButton = BaseButtonWithText(text: "Support", font: UIFont.standard(with: .medium, size: 14), cornerRadius: Constants.cellCornerRadius, borderColor: Constants.green.cgColor)
    let oppositionButton = BaseButtonWithText(text: "Veto", font: UIFont.standard(with: .medium, size: 14), cornerRadius: Constants.cellCornerRadius, borderColor: Constants.red.cgColor)
    let commentTableView = CommentTableView(frame: .zero)
    
    lazy var infoStackView = BaseStackView(subviews: [campaignTypeLabel, campaignDateLabel, UIView()], spacing: 10, axis: .horizontal)
    lazy var buttonStackView = BaseStackView(subviews: [supportButton, oppositionButton, UIView()], spacing: 15, axis: .horizontal, distribution: .fillEqually)
    
    let scrollView = BaseScrollView()
    
    let infoButton = BaseButtonWithImage(image: UIImage(named: "idea"))
    
    //MARK: - Variables
    
    private let db = FirestoreRequest.shared.db
    
    private var floatingCommentView: CommentAnswerView?
    
    private var tipView: EasyTipView?
    
    var campaign: Campaign?
    
    var campaignID: String? {
        didSet {
            if let id = campaignID {
                
                let imagineDataRequest = ImagineDataRequest()
                imagineDataRequest.getSingleCampaign(documentID: id) { (campaign) in
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
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupConstraints()
        showCampaign()
        
        view.backgroundColor = .systemBackground
                
        let scrollViewTap = UITapGestureRecognizer(target: self, action: #selector(scrollViewTapped))
        scrollViewTap.cancelsTouchesInView = false  // Otherwise the tap on the TableViews are not recognized
        scrollView.addGestureRecognizer(scrollViewTap)
        
        scrollView.delegate = self
        
        commentTableView.initializeCommentTableView(section: .proposal, notificationRecipients: nil)
        commentTableView.commentDelegate = self
        
        DispatchQueue.main.async {
            self.createFloatingCommentView()
        }
    }
    
    func setupConstraints() {
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(infoStackView)
        containerView.addSubview(separatorView)
        containerView.addSubview(summaryLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(buttonStackView)
        containerView.addSubview(commentTableView)
        containerView.addSubview(spaceView)
        
        scrollView.fillSuperview()
        containerView.fillSuperview()
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        
        
        titleLabel.constrain(top: containerView.topAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, paddingTop: Constants.padding.standard, paddingLeading: Constants.padding.standard, paddingTrailing: -Constants.padding.standard)
        infoStackView.constrain(top: titleLabel.bottomAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, paddingTop: Constants.padding.standard, paddingLeading: Constants.padding.standard, paddingTrailing: -Constants.padding.standard)
        separatorView.constrain(top: infoStackView.bottomAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, paddingTop: Constants.padding.small / 2, paddingLeading: Constants.padding.standard / 2, paddingTrailing: -Constants.padding.standard / 2, height: 1)
        summaryLabel.constrain(top: separatorView.bottomAnchor, leading: titleLabel.leadingAnchor, trailing: titleLabel.trailingAnchor, paddingTop: Constants.padding.large)
        descriptionLabel.constrain(top: summaryLabel.bottomAnchor, leading: titleLabel.leadingAnchor, trailing: titleLabel.trailingAnchor, paddingTop: Constants.padding.small)
        buttonStackView.constrain(top: descriptionLabel.bottomAnchor, leading: titleLabel.leadingAnchor, trailing: titleLabel.trailingAnchor, paddingTop: Constants.padding.large)
        commentTableView.constrain(top: buttonStackView.bottomAnchor, leading: containerView.leadingAnchor, trailing: containerView.trailingAnchor, paddingTop: Constants.padding.standard)
        spaceView.constrain(top: commentTableView.bottomAnchor, leading: titleLabel.leadingAnchor, bottom: containerView.bottomAnchor, trailing: titleLabel.trailingAnchor, paddingTop: Constants.padding.small, paddingBottom: -Constants.Numbers.commentViewHeight * 2)
        
        spaceView.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)
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
        
        navigationController?.navigationBar.prefersLargeTitles = true
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
        let viewHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        
        if floatingCommentView == nil {
            floatingCommentView = CommentAnswerView(frame: CGRect(x: 0, y: viewHeight-Constants.Numbers.commentViewHeight, width: self.view.frame.width, height: Constants.Numbers.commentViewHeight))
            
            
            floatingCommentView!.delegate = self
            self.containerView.addSubview(floatingCommentView!)
            
            floatingCommentView!.leadingAnchor.constraint(equalTo: self.containerView.leadingAnchor).isActive = true
            floatingCommentView!.trailingAnchor.constraint(equalTo: self.containerView.trailingAnchor).isActive = true
            let bottomConstraint = floatingCommentView!.bottomAnchor.constraint(equalTo: self.containerView.bottomAnchor)
                bottomConstraint.isActive = true
            floatingCommentView!.bottomConstraint = bottomConstraint
            floatingCommentView!.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            floatingCommentView!.addKeyboardObserver()
            
            self.containerView.bringSubviewToFront(floatingCommentView!)
        }
    }
    
    
    func showCampaign() {
        guard let campaign = campaign else { return }
        
        titleLabel.text = campaign.title
        summaryLabel.text = campaign.cellText
        descriptionLabel.text = campaign.descriptionText
        campaignDateLabel.text = campaign.createDate
        campaignTypeLabel.text = campaign.category?.title
        supporterLabel.text = "\(campaign.supporter) Supporter"
        oppositionLabel.text = "\(campaign.opposition) Vetos"
        
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
        
        let language = LanguageSelection().getLanguage()
        
        let collectionRef = (language == .en) ? db.collection("Data").document("en").collection("campaigns") : db.collection("Campaigns")
        
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
        if language == .en {
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
                if language == .en {
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
    
    @objc func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.campaignDetailText)
            // tipView!.show(forItem: infoButton)
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
        if let reportViewController = storyBoard.instantiateViewController(withIdentifier: "reportVC") as? ReportViewController {
            reportViewController.reportComment = true
            reportViewController.modalTransitionStyle = .coverVertical
            reportViewController.modalPresentationStyle = .overFullScreen
            self.present(reportViewController, animated: true, completion: nil)
        }
    }
    
    func commentGotDeleteRequest(comment: Comment, answerToComment: Comment?) {
        self.deleteAlert(title: NSLocalizedString("delete_comment_alert_title", comment: ""), message: NSLocalizedString("delete_comment_alert_message", comment: "you sure? cant be returned"), delete:  { (delete) in
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
