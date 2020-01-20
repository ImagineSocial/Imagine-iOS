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

class FactDetailViewController: UIViewController, ReachabilityObserverDelegate {
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var downvoteButton: DesignableButton!
    @IBOutlet weak var upvoteButton: DesignableButton!
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var upvoteCountLabel: UILabel!
    @IBOutlet weak var downvoteCountLabel: UILabel!
    
    var argument: Argument?
    var fact: Fact?
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setDataUp()
    }
    
    func setDataUp() {
        guard let argument = argument,
        let fact = fact
            else { return }
        
        upvoteCountLabel.text = String(argument.upvotes)
        downvoteCountLabel.text = String(argument.downvotes)
        titleLabel.text = argument.title
        descriptionLabel.text = argument.description
        
//        downvoteButton.layer.borderWidth = 1
//        if #available(iOS 13.0, *) {
//            downvoteButton.layer.borderColor = UIColor.label.cgColor
//        } else {
//            downvoteButton.layer.borderColor = UIColor.black.cgColor
//        }
//        downvoteButton.layer.cornerRadius = downvoteButton.frame.width/2
//        
//        upvoteButton.layer.borderWidth = 1
//        if #available(iOS 13.0, *) {
//            upvoteButton.layer.borderColor = UIColor.label.cgColor
//        } else {
//            upvoteButton.layer.borderColor = UIColor.black.cgColor
//        }
//        upvoteButton.layer.cornerRadius = downvoteButton.frame.width/2
        
        self.navigationItem.title = fact.title
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
        if let vc = segue.destination as? SourceTableViewController {
            if segue.identifier == "toSourceTableView" {
                vc.argument = self.argument
                vc.fact = self.fact
            }
        }
        if let argumentVC = segue.destination as? ArgumentTableViewController {
            if segue.identifier == "toArgumentTableView" {
                argumentVC.argument = self.argument
                argumentVC.fact = self.fact
            }
        }
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        infoButton.showEasyTipView(text: Constants.texts.argumentDetailText)
    }
}
