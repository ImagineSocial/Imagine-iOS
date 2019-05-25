//
//  SourceTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class SourceTableViewController: UITableViewController {
    
    var argument = Argument()
    var sourceList = [String]()

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
        let cell = UITableViewCell()
        
        let source = sourceList[indexPath.row]
        
        if source == "Füge eine Quelle hinzu" {
            cell.textLabel?.font = UIFont.italicSystemFont(ofSize: 14)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        }
        
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.text = source


        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toSourceDetail", sender: nil)
    }
    


}
