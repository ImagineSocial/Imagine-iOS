//
//  ArgumentTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ArgumentTableViewController: UITableViewController {
    
    var argument: Argument?
    var fact: Fact?
    var argumentList = [Argument]()
    
    let identifier = "NibArgumentCell"
    let reuseIdentifier = "addCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        getArguments()
        tableView.layer.cornerRadius = 1
        tableView.separatorStyle = .none
        tableView.backgroundColor = Constants.backgroundColorForTableViews
        
        tableView.register(UINib(nibName: "ArgumentCell", bundle: nil), forCellReuseIdentifier: identifier)
        tableView.register(AddFactCell.self, forCellReuseIdentifier: reuseIdentifier)
        
    }
    
    func getArguments() {
        if let argument = argument, let fact = fact {
            DataHelper().getDeepestArgument(factID: fact.documentID, argumentID: argument.documentID, deepDataType: .arguments) { (deepestData) in
                if let arguments = deepestData as? [Argument] {
                    self.argumentList = arguments
                    self.tableView.reloadData()
                }
            }
        } else {
            print("No Argument or Fact")
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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
            return 50
        } else {
            return 203
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let argument = argumentList[indexPath.row]
        
        if argument.addMoreData {
            if let _ = Auth.auth().currentUser {
                performSegue(withIdentifier: "toNewArgumentSegue", sender: nil)
            } else {
                self.notLoggedInAlert()
            }
        } else {
            performSegue(withIdentifier: "toArgumentDetail", sender: argument)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNewArgumentSegue" {
            if let nav = segue.destination as? UINavigationController {
                if let vc = nav.topViewController as? NewFactViewController {
                    vc.fact = self.fact
                    vc.argument = self.argument
                    vc.new = .deepArgument
                }
            }
        }
        if segue.identifier == "toArgumentDetail" {
            if let vc = segue.destination as? ArgumentDetailViewController {
                if let argument = sender as? Argument {
                    vc.argument = argument
                }
            }
        }
    }

}

