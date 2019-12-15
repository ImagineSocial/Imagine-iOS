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

class FactParentContainerViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contraArgumentCountLabel: UILabel!
    @IBOutlet weak var proArgumentCountLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contraArgumentLabel: UILabel!
    @IBOutlet weak var proArgumentLabel: UILabel!
    
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var factImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var fact:Fact?
    var proArgumentList = [Argument]()
    var contraArgumentList = [Argument]()
    var needNavigationController = false
    
    //MARK:-
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getArguments()
        setPostButton()
        
//        if #available(iOS 13.0, *) {
//            self.view.backgroundColor = .secondarySystemBackground
//            self.navigationController?.view.backgroundColor = .secondarySystemBackground
//        } else {
//            self.view.backgroundColor = UIColor(red: 242.0, green: 242.0, blue: 247.0, alpha: 1.0)
//            self.navigationController?.view.backgroundColor = UIColor(red: 242.0, green: 242.0, blue: 247.0, alpha: 1.0)
//        }
        
        factImageView.layer.cornerRadius = 4
        
        if needNavigationController {
            setDismissButton()
        }
    }
    
    func setDismissButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = Constants.imagineColor
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.setImage(UIImage(named: "Dismiss"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 23).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    func setPostButton() {
        let button = DesignableButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(Constants.imagineColor, for: .normal)
        button.setTitle("Beiträge", for: .normal)
        button.titleLabel?.font = UIFont(name: "IBMPlexSans-Medium", size: 15)
        button.addTarget(self, action: #selector(toPostsTapped), for: .touchUpInside)
        button.layer.borderColor = Constants.imagineColor.cgColor
        button.layer.borderWidth = 1
        button.cornerRadius = 4
        button.clipsToBounds = true
        
        button.heightAnchor.constraint(equalToConstant: 23).isActive = true
        button.widthAnchor.constraint(equalToConstant: 75).isActive = true
        
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    @objc func toPostsTapped() {
        if let fact = self.fact {
            performSegue(withIdentifier: "toPostsSegue", sender: fact)
        }
    }
    
    @objc func dismissTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getArguments() {
        
        if let fact = fact {
            
            
            titleLabel.text = fact.title
            if let url = URL(string: fact.imageURL) {
                factImageView.sd_setImage(with: url, completed: nil)
            } else {
                factImageView.image = UIImage(named: "FactStamp")
            }
            descriptionLabel.text = fact.description
            
            self.view.activityStartAnimating()
            
            DataHelper().getDeepData(documentID: fact.documentID) { (deepData) in // Fetch all Arguments for this fact
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
    }
    
    func setLabels() {
        let nmbOfPro = proArgumentList.count-1
        let nmbOfCon = contraArgumentList.count-1
        
        if let fact = fact {
            if let names = fact.factDisplayNames {
                switch names{
                case .proContra:
                    proArgumentLabel.text = "Pro"
                    contraArgumentLabel.text = "Contra"
                case .confirmDoubt:
                    proArgumentLabel.text = "Bestätigung"
                    contraArgumentLabel.text = "Zweifel"
                case .advantageDisadvantage:
                    proArgumentLabel.text = "Vorteile"
                    contraArgumentLabel.text = "Nachteile"
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
    
    //MARK:-
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProFactTableViewController {
            if segue.identifier == "toProSegue" {
                vc.fact = self.fact
            }
        }
        
        if let contraVC = segue.destination as? ContraFactTableViewController {
            if segue.identifier == "toContraSegue" {
                contraVC.fact = self.fact
            }
        }
        
        if segue.identifier == "toPostsSegue" {
            if let chosenFact = sender as? Fact {
                if let postVC = segue.destination as? PostsOfFactTableViewController {
                    postVC.fact = chosenFact
                }
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        EasyTipView.show(forView: self.view, text: Constants.texts.argumentOverviewText)
    }
    
}
