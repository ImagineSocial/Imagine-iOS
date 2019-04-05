//
//  MeldeTableViewController.swift
//  Imagine
//
//  Created by Malte Schoppe on 04.03.19.
//  Copyright © 2019 Malte Schoppe. All rights reserved.
//

import UIKit

protocol tableViewToContainerParentProtocol:class { // Um die Auswahl zum ParentVC zu schicken
    func passReportOption(option:String)
}

class MeldeTableViewController: UITableViewController {
    
    var reportCategory = ""
    var choosenOption = ""
    var optionArray = [String]()
    var post = Post()
    let reportOptionsClass = ReportOptions()
    
    weak var delegate:tableViewToContainerParentProtocol? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.visibleCells.forEach { (cell) in
            if let cell = cell as? ReportCell {
                cell.ReportReasonLabel.text = ""
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reportOptions()
    }
    
    

    func reportOptions () {
        
        if reportCategory == "Optisch markieren" {
            optionArray = reportOptionsClass.opticOptionArray
        } else if reportCategory == "Schlechte Absicht" {
            optionArray = reportOptionsClass.badIntentionArray
        } else if reportCategory == "Lüge/Täuschung" {
            optionArray = reportOptionsClass.lieDeceptionArray
        } else if reportCategory == "Inhalt" {
            optionArray = reportOptionsClass.contentArray
        } else {
            optionArray = ["Hier stimmt was nicht!"]
        }
        
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return optionArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath) as? ReportCell {

        cell.ReportOptionLabel.text = optionArray[indexPath.row]

        return cell
        }
        return UITableViewCell()
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.visibleCells.forEach { (cell) in      // Jede andere Auswahl zurücksetzen
            if let cell = cell as? ReportCell {
                cell.ReportReasonLabel.text = ""
            }
        }
        if let cell = tableView.cellForRow(at: indexPath) as? ReportCell {      // Ausgewählter Grund markieren
            cell.ReportReasonLabel.text = "X"
            self.choosenOption = optionArray[indexPath.row]
            
            delegate?.passReportOption(option: choosenOption)
        }
        
        
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    

}

class ReportCell : UITableViewCell {
    
    @IBOutlet weak var ReportReasonLabel: UILabel!
    @IBOutlet weak var ReportOptionLabel: UILabel!
}
