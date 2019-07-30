//
//  SourceTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit
import Firebase

class SourceTableViewController: UITableViewController {
    
    var argument = Argument()
    var sourceList = [String]()
    var fact = Fact()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.layer.cornerRadius = 5
        
        sourceList = argument.source
        setSources()
        
        
    }
    
    
    func setSources() {
        
        let newSource = "Füge eine Quelle hinzu"
        
        sourceList.append(newSource)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sourceList.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let source = sourceList[indexPath.row]
        
        if source == "Füge eine Quelle hinzu" {
            
            let cell = UITableViewCell()
            
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = source
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            
            return cell
            
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "sourceCell", for: indexPath) as? sourceCell {
                
                cell.sourceLabel.text = source
                cell.upvoteLabel.text = "▲ 34"
                cell.downvoteLabel.text = "▼ 12"
                
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let source = sourceList[indexPath.row]
        
        if source != "Füge eine Quelle hinzu" {
            performSegue(withIdentifier: "toSourceDetail", sender: nil)
        } else {
            if let _ = Auth.auth().currentUser {
                performSegue(withIdentifier: "toNewSourceSegue", sender: nil)
            } else {
                self.notLoggedInAlert()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 40
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NewFactViewController {
            if segue.identifier == "toNewArgumentSegue" {
                    vc.fact = self.fact
                    vc.new = "source"
            }
        }
    }
    
}

class sourceCell: UITableViewCell {
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var downvoteLabel: UILabel!
    @IBOutlet weak var upvoteLabel: UILabel!
    
}
