//
//  FactParentContainerViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class FactParentContainerViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contraArgumentCountLabel: UILabel!
    @IBOutlet weak var proArgumentCountLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    
    
    var fact:Fact?
    var proArgumentList = [Argument]()
    var contraArgumentList = [Argument]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getArguments()
        
        backgroundView.backgroundColor = Constants.backgroundColorForTableViews
    }
    
    
    
    func getArguments() {
        
        if let fact = fact {
            
            titleLabel.text = fact.title
            
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
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.argumentOverviewText)
    }
    
}
