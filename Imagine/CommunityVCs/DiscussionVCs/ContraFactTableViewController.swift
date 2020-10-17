//
//  ContraFactTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ContraFactTableViewController: UITableViewController {

    var argumentList = [Argument]()
    var fact: Fact?
    var downVotes = 90
    var upvotes = 140
    
    let identifier = "NibArgumentCell"
    let reuseIdentifier = "AddCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ArgumentCell", bundle: nil), forCellReuseIdentifier: identifier)
        tableView.register(AddFactCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    func setArguments(arguments: [Argument]) {
        
        argumentList = arguments
        tableView.reloadData()
        
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return argumentList.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let argument = argumentList[indexPath.row]
        
        if argument.addMoreData {
            if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? AddFactCell {
                
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ArgumentCell {
                
                cell.argument = argument
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let argument = argumentList[indexPath.row]
        
        if argument.addMoreData {
            return 100
        } else {
            return 260
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let argument = argumentList[indexPath.row]
        
        if argument.addMoreData {
            if let _ = Auth.auth().currentUser {
                performSegue(withIdentifier: "toNewArgumentSegue", sender: fact)
            } else {
                self.notLoggedInAlert()
            }
        } else {
            performSegue(withIdentifier: "toDetailFactSegue", sender: argument)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewArgumentSegue" {
            if let nav = segue.destination as? UINavigationController {
                if let vc = nav.topViewController as? NewCommunityItemTableViewController {
                    vc.fact = self.fact
                    vc.new = .argument
                    vc.proOrContra = .contra
                    vc.delegate = self
                }
            }
        }
        
        if let vc = segue.destination as? FactDetailViewController {
            if segue.identifier == "toDetailFactSegue" {
                if let chosenArgument = sender as? Argument {
                    vc.argument = chosenArgument
                    vc.fact = self.fact
                }
            }
        }
    }
}

extension ContraFactTableViewController: NewFactDelegate {
    
    func finishedCreatingNewInstance(item: Any?) {
        if let argument = item as? Argument {
            let count = argumentList.count
            
            self.argumentList.insert(argument, at: count-1)
            self.tableView.reloadData()
        }
    }
}
