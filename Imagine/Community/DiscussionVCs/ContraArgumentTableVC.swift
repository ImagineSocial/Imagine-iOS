//
//  ContraFactTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class ContraArgumentTableVC: UITableViewController {

    var argumentList = [Argument]()
    var community: Community?
    var downVotes = 90
    var upvotes = 140
    
    let identifier = "NibArgumentCell"
    let reuseIdentifier = "AddCell"
    
    weak var delegate: DiscussionChildVCDelegate?


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
                performSegue(withIdentifier: "toNewArgumentSegue", sender: community)
            } else {
                self.notLoggedInAlert()
            }
        } else {
            delegate?.goToDetail(argument: argument)
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewArgumentSegue" {
            if let nav = segue.destination as? UINavigationController {
                if let vc = nav.topViewController as? NewCommunityItemTableVC {
                    vc.community = self.community
                    vc.new = .argument
                    vc.proOrContra = .contra
                    vc.delegate = self
                }
            }
        }
        
        if let vc = segue.destination as? ArgumentViewController {
            if segue.identifier == "toDetailFactSegue" {
                if let chosenArgument = sender as? Argument {
                    vc.argument = chosenArgument
                    vc.community = self.community
                }
            }
        }
    }
}

extension ContraArgumentTableVC: NewFactDelegate {
    
    func finishedCreatingNewInstance(item: Any?) {
        if let argument = item as? Argument {
            let count = argumentList.count
            
            self.argumentList.insert(argument, at: count-1)
            self.tableView.reloadData()
        }
    }
}
