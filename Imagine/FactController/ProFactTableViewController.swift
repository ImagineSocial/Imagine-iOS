//
//  ProFactTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 21.05.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

class ProFactTableViewController: UITableViewController {

    var argumentList = [Argument]()
    var fact = Fact()
    let addArgumentString = "Füge ein Argument hinzu!"
    var downVotes = 80
    var upvotes = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        let identifier = "NibArgumentCell"
        let argument = argumentList[indexPath.row]
        
        //Vielleicht noch absichern?!! Weiß aber nicht wie!
        tableView.register(UINib(nibName: "ArgumentCell", bundle: nil), forCellReuseIdentifier: identifier)

        if argument.title != addArgumentString {
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ArgumentCell {
                
                let row = indexPath.row
                
                if row % 2 != 0 {
                    cell.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
                }
                
                cell.headerLabel.text = argument.title
                cell.bodyLabel.text = argument.description
                cell.proCountLabel.text = "Zustimmen: \(upvotes)"
                cell.contraCountLabel.text = "Zweifel: \(downVotes)"
                
                if argument.source.isEmpty {    // For now, später muss wahrheitswert der Quellen überprüft werden
                    // Keine Quelle
                    cell.sourceLabel.text = "Quelle: 🚫"
                } else {
                    cell.sourceLabel.text = " Quelle: ✅ | ▼ \(downVotes/3)  ▲ \(upvotes/3)"
                }
                
                upvotes = upvotes-17
                downVotes = downVotes-17
                
                return cell
            }
        } else {
            let cell = UITableViewCell()
            
            cell.textLabel?.text = argument.title
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            
            return cell
        }
        

        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var rowHeight:CGFloat = 50
        let argument = argumentList[indexPath.row]
        
        if argument.title != addArgumentString {
            rowHeight = 200
        }
        
        return rowHeight
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let argument = argumentList[indexPath.row]
        
        if argument.title != addArgumentString {
            performSegue(withIdentifier: "toDetailFactSegue", sender: argument)
        } else {
            performSegue(withIdentifier: "toNewArgumentSegue", sender: fact)
        }
    }
    
    //toNewArgumentSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NewFactViewController {
            if segue.identifier == "toNewArgumentSegue" {
                vc.fact = self.fact
                vc.new = "argument"
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


