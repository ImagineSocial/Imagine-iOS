//
//  ArgumentTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 24.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ArgumentTableViewController: UITableViewController {
    
    var argument = Argument()
    var fact = Fact()
    var argumentList = [Argument]()

    override func viewDidLoad() {
        super.viewDidLoad()

        getArguments()
        tableView.layer.cornerRadius = 5
        
    }
    
    func getArguments() {
        
        if fact.documentID != "" {
            DataHelper().getDeepestArgument(factID: fact.documentID, argumentID: argument.documentID) { (deepestData) in
                if let arguments = deepestData as? [Argument] {
                    self.argumentList = arguments
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return argumentList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "NibArgumentCell"
        let argument = argumentList[indexPath.row]
        
        //Vielleicht noch absichern?!! Weiß aber nicht wie!
        tableView.register(UINib(nibName: "ArgumentCell", bundle: nil), forCellReuseIdentifier: identifier)
        
        if argument.title != "Füge ein Argument hinzu!" {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ArgumentCell {
                
                
                cell.headerLabel.text = argument.title
                cell.bodyLabel.text = argument.description
                cell.proCountLabel.text = "Zustimmen: 150"
                cell.contraCountLabel.text = "Zweifel: 78"
                
                if argument.source.isEmpty {    // For now, später muss wahrheitswert der Quellen überprüft werden
                    // Keine Quelle
                    cell.sourceLabel.text = "Quelle: 🚫"
                } else {
                    cell.sourceLabel.text = "Quelle: ✅"
                }
                
                return cell
            }
        } else {
            let cell = UITableViewCell()
            
            cell.textLabel?.text = argument.title
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            
            return cell
        }
        
        
        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var rowHeight:CGFloat = 50
        let argument = argumentList[indexPath.row]
        
        if argument.title != "Füge ein Argument hinzu!" {
            rowHeight = 203
        }
        
        return rowHeight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let argument = argumentList[indexPath.row]
        
        if argument.title != "Füge ein Argument hinzu!" {
            performSegue(withIdentifier: "toArgumentDetail", sender: nil)
        } else {
            performSegue(withIdentifier: "toNewArgumentSegue", sender: argument)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NewFactViewController {
            if segue.identifier == "toNewArgumentSegue" {
                if let argument = sender as? Argument {
                    vc.deepArgument = argument
                    vc.fact = self.fact
                    vc.new = "deepArgument"
                }
            }
        }
    }

}
