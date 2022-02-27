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
import FirebaseAnalytics

protocol RecentTopicDelegate: class {
    func topicSelected(community: Community)
}

class DiscussionParentVC: UIViewController {
    
    @IBOutlet weak var contraArgumentCountLabel: UILabel!
    @IBOutlet weak var proArgumentCountLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contraArgumentLabel: UILabel!
    @IBOutlet weak var proArgumentLabel: UILabel!
    @IBOutlet weak var offsetLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoButton: UIButton!
    
    var community: Community?
    var proArgumentList = [Argument]()
    var contraArgumentList = [Argument]()
    var needNavigationController = false
    let db = FirestoreRequest.shared.db
    let radius:CGFloat = 6
    
    var tipView: EasyTipView?
    
    weak var pageViewHeaderDelegate: PageViewHeaderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let community = community {
            self.getArguments(for: community)
        }
                
        if needNavigationController {
            setDismissButton()
        }
        
        offsetLayoutConstraint.constant = Constants.Numbers.communityHeaderHeight + 20
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

    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getArguments(for community: Community) {
        
        DataRequest().getDeepData(fact: community) { (deepData) in // Fetch all Arguments for this fact
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
        
        if let community = community, let names = community.factDisplayNames {
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
        
        proArgumentCountLabel.text = "(\(nmbOfPro))"
        contraArgumentCountLabel.text = "(\(nmbOfCon))"
    }
    
    func sendData(ProArguments : [Argument], ContraArguments: [Argument]) {     // Send to ContainerViews (TableViews)
        
        if let ProChildVC = children.last as? ProArgumentTableVC {
            ProChildVC.setArguments(arguments: ProArguments)
        }

        if let ContraChildVC = children.first as? ContraArgumentTableVC {
            ContraChildVC.setArguments(arguments: ContraArguments)
        }
    }
    
    //MARK:-
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProArgumentTableVC {
            if segue.identifier == "toProSegue" {
                vc.community = self.community
            }
        }
        
        if let contraVC = segue.destination as? ContraArgumentTableVC {
            if segue.identifier == "toContraSegue" {
                contraVC.community = self.community
            }
        }
        
        if segue.identifier == "toPostsSegue" {
            if let chosenCommunity = sender as? Community {
                if let postVC = segue.destination as? CommunityFeedTableVC {
                    postVC.community = chosenCommunity
                }
            }
        }
        
        if segue.identifier == "toSettingSegue" {
            if let fact = sender as? Community {
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
        if let community = community {
            performSegue(withIdentifier: "toSettingSegue", sender: community)
        }
    }
}
