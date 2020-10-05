//
//  FactParentContainerViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import EasyTipView
import Firebase

protocol RecentTopicDelegate {
    func topicSelected(fact: Fact)
}

class FactParentContainerViewController: UIViewController {
    
    @IBOutlet weak var contraArgumentCountLabel: UILabel!
    @IBOutlet weak var proArgumentCountLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contraArgumentLabel: UILabel!
    @IBOutlet weak var proArgumentLabel: UILabel!
    
    @IBOutlet weak var infoButton: UIButton!
    
    var fact:Fact?
    var proArgumentList = [Argument]()
    var contraArgumentList = [Argument]()
    var needNavigationController = false
    let db = Firestore.firestore()
    let radius:CGFloat = 6
    
    var tipView: EasyTipView?
    
    var pageViewHeaderDelegate: PageViewHeaderDelegate?
    //MARK:-
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let topic = fact {
            self.getArguments(topic: topic)
            self.setUI(topic: topic)
        }
//        setPostButton()
                
        if needNavigationController {
            setDismissButton()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .imagineColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }

    
    @objc func toPostsTapped() {
        if let fact = self.fact {
            performSegue(withIdentifier: "toPostsSegue", sender: fact)
        }
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setUI(topic: Fact) {
//        if let user = Auth.auth().currentUser {
//            for moderator in topic.moderators {
//                if moderator == user.uid {
//                    self.moderatorView.isHidden = false
//                }
//            }
//        }
        
        
    }
    
    func getArguments(topic: Fact) {
        
        DataHelper().getDeepData(fact: topic) { (deepData) in // Fetch all Arguments for this fact
            if let arguments = deepData as? [Argument] {
                for argument in arguments {
                    if argument.proOrContra == "pro" {      // Sort the Arguments
                        self.proArgumentList.append(argument)
                    } else {    //contra
                        self.contraArgumentList.append(argument)
                    }
                }
                self.sendData(ProArguments: self.proArgumentList, ContraArguments: self.contraArgumentList) // Send to ContainerViews
                self.setLabels()
                
                self.view.activityStopAnimating()
            }
        }
    }
    
    func setLabels() {
        let nmbOfPro = proArgumentList.count-1
        let nmbOfCon = contraArgumentList.count-1
        
        if let fact = fact {
            if let names = fact.factDisplayNames {
                switch names{
                case .proContra:
                    proArgumentLabel.text = NSLocalizedString("discussion_pro", comment: "pro")
                    contraArgumentLabel.text = NSLocalizedString("discussion_contra", comment: "contra")
                case .confirmDoubt:
                    proArgumentLabel.text = NSLocalizedString("discussion_proof", comment: "proof")
                    contraArgumentLabel.text = NSLocalizedString("discussion_doubt", comment: "doubt")
                case .advantageDisadvantage:
                    proArgumentLabel.text = NSLocalizedString("discussion_advantage", comment: "advantage")
                    contraArgumentLabel.text = NSLocalizedString("discussion_disadvantage", comment: "disadvantage")
                }
            }
        }
    
        proArgumentCountLabel.text = "(\(nmbOfPro))"
        contraArgumentCountLabel.text = "(\(nmbOfCon))"
    }
    
    func sendData(ProArguments : [Argument], ContraArguments: [Argument]) {     // Send to ContainerViews (TableViews)
        
        if let ProChildVC = children.last as? ProFactTableViewController {
            ProChildVC.setArguments(arguments: ProArguments)
        }

        if let ContraChildVC = children.first as? ContraFactTableViewController {
            ContraChildVC.setArguments(arguments: ContraArguments)
        }
    }
    
    func followTopic(fact: Fact) {
        if let user = Auth.auth().currentUser {
            let topicRef = db.collection("Users").document(user.uid).collection("topics").document(fact.documentID)
            
            topicRef.setData(["createDate": Timestamp(date: Date())]) { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    print("Succesfully subscribed to topic")
                    fact.beingFollowed = true
                    self.updateFollowCount(fact: fact, follow: true)
                }
            }
        } 
    }
    
    func unfollowTopic(fact: Fact) {
        if let user = Auth.auth().currentUser {
            let topicRef = db.collection("Users").document(user.uid).collection("topics").document(fact.documentID)
            
            topicRef.delete { (err) in
                if let error = err {
                    print("We have an error: \(error.localizedDescription)")
                } else {
                    fact.beingFollowed = false
                    print("Successfully unfollowed")
                    self.updateFollowCount(fact: fact, follow: false)
                }
            }
        }
    }
    
    func updateFollowCount(fact: Fact, follow: Bool) {
        if let user = Auth.auth().currentUser {
            var collectionRef: CollectionReference!
            if fact.language == .english {
                collectionRef = db.collection("Data").document("en").collection("topics")
            } else {
                collectionRef = db.collection("Facts")
            }
            let ref = collectionRef.document(fact.documentID)
            
            if follow {
                ref.updateData([
                    "follower" : FieldValue.arrayUnion([user.uid])
                ])
            } else { //unfollowed
                ref.updateData([
                    "follower": FieldValue.arrayRemove([user.uid])
                ])
            }
        }
    }
    
    //MARK:-
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProFactTableViewController {
            if segue.identifier == "toProSegue" {
                vc.fact = self.fact
            }
            Analytics.logEvent("TappedOnArgument", parameters: [
                AnalyticsParameterTerm: ""
            ])
        }
        
        if let contraVC = segue.destination as? ContraFactTableViewController {
            if segue.identifier == "toContraSegue" {
                contraVC.fact = self.fact
            }
            Analytics.logEvent("TappedOnArgument", parameters: [
                AnalyticsParameterTerm: ""
            ])
        }
        
        if segue.identifier == "toPostsSegue" {
            if let chosenFact = sender as? Fact {
                if let postVC = segue.destination as? PostsOfFactTableViewController {
                    postVC.fact = chosenFact
                }
            }
        }
        
        if segue.identifier == "toSettingSegue" {
            if let fact = sender as? Fact {
                if let vc = segue.destination as? SettingTableViewController {
                    vc.topic = fact
                    vc.settingFor = .community
                }
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        if let tipView = tipView {
            tipView.dismiss()
        } else {
            tipView = EasyTipView(text: Constants.texts.argumentOverviewText)
            tipView!.show(forView: self.view)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let tipView = tipView {
            tipView.dismiss()
        }
    }
    
    @IBAction func toSettingsTapped(_ sender: Any) {
        if let fact = fact {
            performSegue(withIdentifier: "toSettingSegue", sender: fact)
        }
    }
}
